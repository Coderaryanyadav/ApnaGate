
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

      final String? userWing = profile?['wing'];
      final String? userFlat = profile?['flat_number'];

      final relevantVisitors = data.where((e) => 
        // Monitor ALL statuses to handle cancellations
        // Strict Filter: Must match Wing & Flat (if set)
        (userWing != null && e['wing'] == userWing) &&
        (userFlat != null && e['flat_number'] == userFlat) 
      ).toList();

      for (var visit in relevantVisitors) {
        final id = visit['id'] as String;
          
          // Deterministic Notification ID based on Visitor ID
          final notificationId = id.hashCode;

          if (visit['status'] == 'pending') {
            // Check local memory AND persistent storage for pending visitors
            if (!knownIds.contains(id) && !alertedIds.contains(id)) {
              knownIds.add(id);
              
              final createdAt = DateTime.tryParse(visit['created_at'] ?? '') ?? DateTime(2000);
              // Freshness check (45s) - Ultra Strict
              final isFresh = createdAt.isAfter(DateTime.now().subtract(const Duration(seconds: 45)));

              // Double check persistence immediately before showing
              final alreadyAlerted = await PersistenceHelper.loadAlertedIds();
              if (isFresh && !alreadyAlerted.contains(id)) {
                // Save FIRST to prevent race conditions
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
                      'apna_gate_alarm_v2',
                      'Critical Alerts',
                      importance: Importance.max,
                      priority: Priority.high,
                      sound: RawResourceAndroidNotificationSound('notification'),
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

