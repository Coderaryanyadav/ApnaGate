
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
        autoStart: true,
        isForegroundMode: true, // Re-enabled to ensure alarms work
        notificationChannelId: 'apna_bg_service',
        initialNotificationTitle: 'ApnaGate Security',
        initialNotificationContent: 'Active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
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
  StreamSubscription? notificationSub;
  Timer? watchmanAlertTimer; // Night shift alerts

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
    watchmanAlertTimer?.cancel();
    
    // Start visitor monitoring (for residents)
    visitorSub = _startVisitorStream(userId, token, localNotif);
    
    // Start general notification monitoring (guest entry, househelp for all users)
    notificationSub = _startNotificationStream(userId, token, localNotif);
    
    // Start SOS monitoring + Watchman Alerts (for guards and admins)
    if (role == 'guard' || role == 'admin') {
      sosSub = _startSOSStream(token, localNotif);
      
      // Start watchman alert scheduler (checks time every minute)
      // This ensures alerts fire exactly at 12:00, 12:30, 01:00... not just 30 mins from app start
      watchmanAlertTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
         final now = DateTime.now();
         final minute = now.minute;
         final hour = now.hour;
         
         // 1. Regular "Are you awake?" check at :00 and :30
         // Fire only at :00 and :30, and only if seconds < 60
         if ((minute == 0 || minute == 30)) {
           await _checkAndTriggerWatchmanAlert(userId, token, localNotif);
         }
         
         // 2. PATROL COMPLIANCE CHECKS (Strict 3-Scan Rule)
         // Check at 02:00, 04:00, 06:00
         if (minute == 0) {
            if (hour == 2) {
               await _checkPatrolCompliance(userId, token, localNotif, minScansRequired: 1, deadlineLabel: '2 AM');
            } else if (hour == 4) {
               await _checkPatrolCompliance(userId, token, localNotif, minScansRequired: 2, deadlineLabel: '4 AM');
            } else if (hour == 6) {
               await _checkPatrolCompliance(userId, token, localNotif, minScansRequired: 3, deadlineLabel: '6 AM');
            }
         }
      });
      
      // Also check immediately on start/restart to catch missed slots
      Future.delayed(const Duration(seconds: 5), () {
        _checkAndTriggerWatchmanAlert(userId, token, localNotif);
      });
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
    watchmanAlertTimer?.cancel();
    watchmanAlertTimer = null;
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
              
              // 🛑 DISABLED: Relying on OneSignal Push to avoid duplication
              // await notif.show(
              //   notificationId,
              //   '🔔 New Visitor',
              //   '${visit['visitor_name']} is waiting',
              //   const NotificationDetails(
              //     android: AndroidNotificationDetails(
              //       'apna_gate_alarm_v3',
              //       'Critical Alerts',
              //       importance: Importance.max,
              //       priority: Priority.max,
              //       playSound: true,
              //       sound: RawResourceAndroidNotificationSound('notification'),
              //       fullScreenIntent: true,
              //     ),
              //   ),
              // );
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
            if (age.inSeconds > 300) continue; // Allow notifications within 5 minutes (Fixed from 10s)
          }
        }
        
        handledIds.add(id);
        
        // 🛑 DISABLED: Relying on OneSignal Push to avoid duplication
        // await notif.show(
        //   id.hashCode,
        //   notification['title'] ?? 'Notification',
        //   notification['message'] ?? '',
        //   const NotificationDetails(
        //     android: AndroidNotificationDetails(
        //       'apna_gate_alarm_v3',
        //       'Critical Alerts',
        //       importance: Importance.max,
        //       priority: Priority.max,
        //       playSound: true,
        //       sound: RawResourceAndroidNotificationSound('notification'),
        //       fullScreenIntent: true,
        //     ),
        //   ),
        // );
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
            if (age.inSeconds > 300) continue; // Alert if within last 5 minutes
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

/// Watchman Alert System - Check if it's night shift time and trigger alert
Future<void> _checkAndTriggerWatchmanAlert(String userId, String token, FlutterLocalNotificationsPlugin notif) async {
  // Check if current time is between 12 AM (00:00) and 6 AM (06:00)
  final now = DateTime.now();
  final currentHour = now.hour;
  
  // Only trigger during night shift (12 AM to 6 AM)
  if (currentHour < 0 || currentHour >= 6) {
    return; // Not night time
  }
  
  try {
    final client = SupabaseClient(
      SupabaseConfig.url, 
      SupabaseConfig.anonKey,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    // Create alert record in database (Let DB generate UUID)
    final response = await client.from('watchman_alerts').insert({
      'guard_id': userId,
      'alert_time': DateTime.now().toUtc().toIso8601String(),
      'status': 'pending',
    }).select().single();
    
    final alertId = response['id'] as String;
    
    // Trigger full-screen notification
    await notif.show(
      alertId.hashCode,
      '⏰ WATCHMAN ALERT',
      'Are you awake? Tap to confirm!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'apna_gate_alarm_v3',
          'Watchman Alerts',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          fullScreenIntent: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          autoCancel: false, // Don't dismiss automatically
          ongoing: true, // Keep it persistent
        ),
      ),
    );
    
    debugPrint('Watchman alert triggered for guard: $userId');
  } catch (e) {
    debugPrint('Watchman alert error: $e');
  }
}

/// PATROL COMPLIANCE CHECK
/// Enforces minimum number of scans by specific times.
Future<void> _checkPatrolCompliance(
    String userId, 
    String token, 
    FlutterLocalNotificationsPlugin notif, 
    {required int minScansRequired, required String deadlineLabel}) async {
  
  try {
    final client = SupabaseClient(
      SupabaseConfig.url, 
      SupabaseConfig.anonKey,
      headers: {'Authorization': 'Bearer $token'},
    );

    // Using a simple "last 12 hours" window to catch the night shift scans
    final since = DateTime.now().toUtc().subtract(const Duration(hours: 12)).toIso8601String();
    
    final response = await client.from('patrol_logs')
        .select('id')
        .eq('guard_id', userId)
        .gte('created_at', since)
        .count(CountOption.exact);
        
    final scanCount = response.count;
    
    if (scanCount < minScansRequired) {
      // 🚨 FAILED COMPLIANCE - ALARM!
      final alarmId = DateTime.now().millisecondsSinceEpoch;
      
      await notif.show(
        alarmId,
        '🚨 PATROL MISSED!',
        'You have only done $scanCount scans. Required: $minScansRequired by $deadlineLabel. GO SCAN NOW!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'apna_gate_alarm_v3',
            'Critical Alerts',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification'), // Use SOS sound
            fullScreenIntent: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            autoCancel: false,
            ongoing: true, // Cannot dismiss easily
            color: Color(0xFFFF0000), // RED
            ledColor: Color(0xFFFF0000),
            ledOnMs: 500,
            ledOffMs: 500,
          ),
        ),
      );
      
      debugPrint('Patrol Compliance Failed: $scanCount/$minScansRequired');
    } else {
      debugPrint('Patrol Compliance Passed: $scanCount/$minScansRequired');
    }
  } catch (e) {
    debugPrint('Error checking patrol compliance: $e');
  }
}
