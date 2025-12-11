
import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/persistence_helper.dart'; // Added
import '../supabase_config.dart';

// Entry point
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'apna_bg_service',
    'Background Monitor',
    description: 'Keeps connection alive',
    importance: Importance.low, 
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true, // Re-enabled to ensure alarms work
      notificationChannelId: 'apna_bg_service',
      initialNotificationTitle: 'ApnaGate Security',
      initialNotificationContent: 'Active',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();
  
  // Init Channel for Alerts
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'apna_gate_alarm_v2', 
    'Critical Alerts',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
  );
  await localNotif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(alertChannel);

  // Subscription holder
  StreamSubscription? visitorSub;

  // Listen for User Data
  service.on('start_monitoring').listen((event) {
    if (event == null) return;
    
    // Check if we are already monitoring this user to avoid duplicate streams
    final String userId = event['user_id'];
    
    visitorSub?.cancel();
    final String token = event['token']; // Auth Token for RLS
    
    visitorSub = _startSupabaseStream(userId, token, localNotif);
  });

  // Listen for Logout
  service.on('stop_monitoring').listen((event) {
    visitorSub?.cancel();
    visitorSub = null;
  });
}

StreamSubscription _startSupabaseStream(String userId, String token, FlutterLocalNotificationsPlugin notif) {
  // Manual Supabase Client (No Auth Flow, just specific queries)
  final client = SupabaseClient(
    SupabaseConfig.url, 
    SupabaseConfig.anonKey,
    headers: {'Authorization': 'Bearer $token'}, // Pass Auth Token
  );
  
  final Set<String> knownIds = {};
  
  // Visitor Stream
  return client.from('visitors')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> data) async {
      final alertedIds = await PersistenceHelper.loadAlertedIds();
      
      // Fetch user profile to filter by Wing/Flat (Matching UI Logic)
      final profile = await client.from('profiles')
          .select('wing, flat_number')
          .eq('id', userId)
          .maybeSingle();

      final String? userWing = profile?['wing']?.toString().toUpperCase();
      final String? userFlat = profile?['flat_number']?.toString().toUpperCase();

      final relevantVisitors = data.where((e) => 
        (userWing != null && e['wing']?.toString().toUpperCase() == userWing) &&
        (userFlat != null && e['flat_number']?.toString().toUpperCase() == userFlat) 
      ).toList();

      for (var visit in relevantVisitors) {
        final id = visit['id'] as String;
          
          final notificationId = id.hashCode;

          if (visit['status'] == 'pending') {
            if (!knownIds.contains(id) && !alertedIds.contains(id)) {
              knownIds.add(id);
              
              // 🌍 UTC Handling: Convert everything to UTC to avoid device timezone issues
              final createdAtStr = visit['created_at'] ?? '';
              final createdAt = DateTime.tryParse(createdAtStr)?.toUtc() ?? DateTime(2000).toUtc();
              final nowUtc = DateTime.now().toUtc();
              
              // Freshness: 5s window (Ultra-Tight) - Prevent old alerts on restart
              final isFresh = createdAt.isAfter(nowUtc.subtract(const Duration(seconds: 10)));

              // Double check persistence
              final alreadyAlerted = await PersistenceHelper.loadAlertedIds();
              if (isFresh && !alreadyAlerted.contains(id)) {
                await PersistenceHelper.saveAlertedId(id);
                // Update local memory
                alertedIds.add(id); 
                knownIds.add(id);
                
                // Trigger Notification
                await notif.show(
                  notificationId, // <--- DETEMINISTIC ID
                  '🔔 New Visitor',
                  '${visit['visitor_name']} is waiting',
                  const NotificationDetails(
                    android: AndroidNotificationDetails(
                      'apna_gate_alarm_v3', // Force Channel Upgrade
                      'Critical Alerts',
                      importance: Importance.max,
                      priority: Priority.max,
                      playSound: true,
                      sound: RawResourceAndroidNotificationSound('notification'),
                      fullScreenIntent: true, // Force POP UP
                    ),
                  ),
                );
              }
            }
          } else {
             // 🛑 Status CHANGED (Approved/Denied/Exit)
             // Cancel the notification if it exists
             await notif.cancel(notificationId);
          }
      }
    });
}

