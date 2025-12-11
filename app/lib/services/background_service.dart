
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/persistence_helper.dart';
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

  try {
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
  } catch (e) {
    debugPrint('Background Service Init Failed: $e');
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();
  
  // Init Channel for Alerts
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'apna_gate_alarm_v3', 
    'Critical Alerts',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
  );
  await localNotif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(alertChannel);

  // Subscription holders
  StreamSubscription? visitorSub;
  StreamSubscription? sosSub;
  StreamSubscription? notificationSub; // For guest entry & househelp

  // Listen for User Data
  service.on('start_monitoring').listen((event) {
    if (event == null) return;
    
    final String userId = event['user_id'];
    final String token = event['token'];
    final String? role = event['role'];
    
    // Cancel existing subscriptions
    visitorSub?.cancel();
    sosSub?.cancel();
    notificationSub?.cancel();
    
    // Start visitor monitoring (for residents)
    visitorSub = _startVisitorStream(userId, token, localNotif);
    
    // Start general notification monitoring (guest entry, househelp for all users)
    notificationSub = _startNotificationStream(userId, token, localNotif);
    
    // Start SOS monitoring (for guards and admins)
    if (role == 'guard' || role == 'admin') {
      sosSub = _startSOSStream(token, localNotif);
    }
  });

  // Listen for Logout
  service.on('stop_monitoring').listen((event) {
    visitorSub?.cancel();
    visitorSub = null;
    sosSub?.cancel();
    sosSub = null;
    notificationSub?.cancel();
    notificationSub = null;
  });
}

/// Monitor visitors table for pending visitor requests
StreamSubscription _startVisitorStream(String userId, String token, FlutterLocalNotificationsPlugin notif) {
  final client = SupabaseClient(
    SupabaseConfig.url, 
    SupabaseConfig.anonKey,
    headers: {'Authorization': 'Bearer $token'},
  );
  
  final Set<String> knownIds = {};
  
  return client.from('visitors')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> data) async {
      final alertedIds = await PersistenceHelper.loadAlertedIds();
      
      // Fetch user profile to filter by Wing/Flat
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
            
            final createdAtStr = visit['created_at'] ?? '';
            final createdAt = DateTime.tryParse(createdAtStr)?.toUtc() ?? DateTime(2000).toUtc();
            final nowUtc = DateTime.now().toUtc();
            
            final isFresh = createdAt.isAfter(nowUtc.subtract(const Duration(seconds: 10)));

            final alreadyAlerted = await PersistenceHelper.loadAlertedIds();
            if (isFresh && !alreadyAlerted.contains(id)) {
              await PersistenceHelper.saveAlertedId(id);
              alertedIds.add(id); 
              knownIds.add(id);
              
              await notif.show(
                notificationId,
                '🔔 New Visitor',
                '${visit['visitor_name']} is waiting',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'apna_gate_alarm_v3',
                    'Critical Alerts',
                    importance: Importance.max,
                    priority: Priority.max,
                    playSound: true,
                    sound: RawResourceAndroidNotificationSound('notification'),
                    fullScreenIntent: true,
                  ),
                ),
              );
            }
          }
        } else {
          await notif.cancel(notificationId);
        }
      }
    });
}

/// Monitor notifications table for guest entry & househelp
StreamSubscription _startNotificationStream(String userId, String token, FlutterLocalNotificationsPlugin notif) {
  final client = SupabaseClient(
    SupabaseConfig.url, 
    SupabaseConfig.anonKey,
    headers: {'Authorization': 'Bearer $token'},
  );
  
  final Set<String> handledIds = {};
  
  return client.from('notifications')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> data) async {
      // Filter for this user and unread notifications
      final userNotifications = data.where((n) => 
        n['user_id'] == userId && n['read'] == false
      ).toList();
      
      for (var notification in userNotifications) {
        final id = notification['id'] as String;
        
        if (handledIds.contains(id)) continue;
        
        final createdAtStr = notification['created_at'];
        if (createdAtStr != null) {
          final created = DateTime.tryParse(createdAtStr)?.toUtc();
          if (created != null) {
            final age = DateTime.now().toUtc().difference(created);
            if (age.inSeconds > 10) continue; // Only fresh notifications
          }
        }
        
        handledIds.add(id);
        
        await notif.show(
          id.hashCode,
          notification['title'] ?? 'Notification',
          notification['message'] ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'apna_gate_alarm_v3',
              'Critical Alerts',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('notification'),
              fullScreenIntent: true,
            ),
          ),
        );
      }
    });
}

/// Monitor SOS alerts for guards and admins
StreamSubscription _startSOSStream(String token, FlutterLocalNotificationsPlugin notif) {
  final client = SupabaseClient(
    SupabaseConfig.url, 
    SupabaseConfig.anonKey,
    headers: {'Authorization': 'Bearer $token'},
  );
  
  final Set<String> handledSOS = {};
  
  return client.from('sos_alerts')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> data) async {
      // Filter for active SOS only
      final activeSOS = data.where((alert) => alert['status'] == 'active').toList();
      
      for (var alert in activeSOS) {
        final id = alert['id'] as String;
        
        if (handledSOS.contains(id)) continue;
        
        final createdAtStr = alert['created_at'];
        if (createdAtStr != null) {
          final created = DateTime.tryParse(createdAtStr)?.toUtc();
          if (created != null) {
            final age = DateTime.now().toUtc().difference(created);
            if (age.inSeconds > 30) continue; // Only very fresh SOS
          }
        }
        
        handledSOS.add(id);
        
        final wing = alert['wing'] ?? 'Unknown';
        final flat = alert['flat_number'] ?? alert['flatNumber'] ?? 'Unknown';
        final residentName = alert['resident_name'] ?? alert['residentName'] ?? 'Unknown';
        
        await notif.show(
          id.hashCode,
          '🚨 SOS ALERT',
          'EMERGENCY at $wing-$flat by $residentName',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'apna_gate_alarm_v3',
              'Emergency Alerts',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('notification'),
              fullScreenIntent: true,
              enableVibration: true,
              visibility: NotificationVisibility.public,
            ),
          ),
        );
      }
    });
}
