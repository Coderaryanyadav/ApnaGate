import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/ads_service.dart';
import 'supabase_config.dart';
import 'widgets/error_boundary.dart';
import 'package:flutter/foundation.dart'; // Added for BindingBase

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:audioplayers/audioplayers.dart'; // Added

import 'services/background_service.dart';

void main() async {
  // 1. Init Bindings + Disable Zone Warning
  WidgetsFlutterBinding.ensureInitialized();
  BindingBase.debugZoneErrorsAreFatal = false;
  
  // 🔴 CRITICAL: Catch all async errors globally
  await runZonedGuarded(() async {
    // Init Background Service (Config only)
    await initializeBackgroundService();

    // 📦 Init Hive (Offline Cache)
    await Hive.initFlutter();
    await Hive.openBox('user_cache');
    await Hive.openBox('patrol_logs'); // For logs
    
    // ONLY critical initialization - everything else lazy loaded
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    // 🛡️ Wrap app with ErrorBoundary to catch all errors
    runApp(
      const ErrorBoundary(
        child: ProviderScope(child: ApnaGateApp()),
      ),
    );
    
    // Initialize everything else in background AFTER app starts
    // ignore: unawaited_futures
    Future.microtask(() async {
      await AdsService.initialize();
      await _initOneSignalBackground();
    });
  }, (error, stack) {
    // Log all uncaught errors
    debugPrint('🔴 Uncaught error: $error');
    debugPrint('Stack trace: $stack');
    // Note: Crash reporting service (Sentry) should be connected here
  });
}

Future<void> _initOneSignalBackground() async {
  try {
     // await OneSignal.Debug.setLogLevel(OSLogLevel.verbose); // Disabled for production
    OneSignal.initialize(SupabaseConfig.oneSignalAppId);
    
    // Wait for OneSignal to be ready
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Request permission and wait for it
    await OneSignal.Notifications.requestPermission(true);
    
    // Wait for subscription to be active
    await Future.delayed(const Duration(milliseconds: 1000));
    
    debugPrint('✅ OneSignal initialized and ready');

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // 🤫 1. Create Silent Channel for Background Service (Stealth Mode)
    const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
      'apna_bg_service',
      'Background Monitor',
      description: 'Keeps the app running to listen for doorbell',
      importance: Importance.low, // Silent, minified
      playSound: false,
      showBadge: false,
    );

    // 🔔 2. Force High Priority Channel for Sound
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'apna_gate_alarm_v3', // Updated to v3 to force config refresh
      'Emergency Alarms',
      description: 'Loud notifications for visitor arrivals',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
    );
    
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    await androidPlugin?.createNotificationChannel(serviceChannel); // Create Silent
    await androidPlugin?.createNotificationChannel(channel);        // Create SOS Loud

    // 🔔 3. Create Standard Channel (v1) with High Importance as well
    // This fixes the "Guest Arrived" sound/delay issue by ensuring it's not treated as low priority
    const AndroidNotificationChannel standardChannel = AndroidNotificationChannel(
      'apna_gate_alarm_v1', // Standard channel used by backend
      'Visitor Notifications',
      description: 'Notifications for guest arrivals',
      importance: Importance.max, // High importance to pop up
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(standardChannel);

    // 🔔 4. CRITICAL: Add notification click handler to open app
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('✅ Notification clicked: ${event.notification.title}');
      // The app will automatically open when notification is clicked
      // Additional navigation logic can be added here based on notification data
    });

    // 🔔 5. Force notification to show in foreground with Sound
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      bool shouldShow = true;
      
      try {
        final data = event.notification.additionalData;
        
        // 1. Strict Time Check (1 Minute Max)
        if (data != null && data['created_at'] != null) {
           final created = DateTime.tryParse(data['created_at'].toString())?.toUtc();
           if (created != null) {
              final int diff = DateTime.now().toUtc().difference(created).inMinutes.abs();
              
              if (diff > 1) { // 🛑 Strict 1 Minute Cutoff
                 shouldShow = false; 
                 debugPrint('🚫 Main: Suppressed OLD notification (${diff}m ago): ${event.notification.title}');
              }
           }
        }
        
        // 2. Extra Safety: Status Check if present
        if (data != null && data['status'] != null) {
           final status = data['status'].toString().toLowerCase();
           if (status == 'approved' || status == 'rejected' || status == 'completed') {
              shouldShow = false;
              debugPrint('🚫 Main: Suppressed PROCESSED notification ($status)');
           }
        }

      } catch (e) {
         // Default to show if parsing fails
      }
      
      if (shouldShow) {
         event.notification.display();
         debugPrint('✅ Displaying notification: ${event.notification.title}');
      } else {
         event.preventDefault(); // 🛑 HARD STOP
      }
    });
  } catch (e) {
    // Silent fail
    debugPrint('OneSignal init error: $e');
  }
}
