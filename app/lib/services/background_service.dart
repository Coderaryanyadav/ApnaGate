
import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

// Entry point
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'crescent_bg_service',
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
      notificationChannelId: 'crescent_bg_service',
      initialNotificationTitle: 'Crescent Gate Security',
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
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();
  
  // Init Channel for Alerts
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'crescent_gate_alarm_v2', 
    'Critical Alerts',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
  );
  await localNotif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(alertChannel);

  // Listen for User Data
  service.on('start_monitoring').listen((event) {
    if (event == null) return;
    final String userId = event['user_id'];
    final String token = event['token']; // Auth Token for RLS
    
    _startSupabaseStream(userId, token, localNotif);
  });
}

void _startSupabaseStream(String userId, String token, FlutterLocalNotificationsPlugin notif) {
  // Manual Supabase Client (No Auth Flow, just specific queries)
  final client = SupabaseClient(
    SupabaseConfig.url, 
    SupabaseConfig.anonKey,
    headers: {'Authorization': 'Bearer $token'}, // Pass Auth Token
  );
  
  final Set<String> knownIds = {};
  
  // Visitor Stream
  client.from('visitors')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> data) {
      
      final myPending = data.where((e) => 
        e['resident_id'] == userId && 
        e['status'] == 'pending'
      ).toList();

      for (var visit in myPending) {
        final id = visit['id'] as String;
        if (!knownIds.contains(id)) {
          knownIds.add(id);
          
          // Trigger Notification
          notif.show(
            DateTime.now().millisecond,
            '🔔 New Visitor',
            '${visit['visitor_name']} is waiting (Background)',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'crescent_gate_alarm_v2',
                'Critical Alerts',
                importance: Importance.max,
                priority: Priority.high,
                sound: RawResourceAndroidNotificationSound('notification'),
              ),
            ),
          );
        }
      }
    });
}
