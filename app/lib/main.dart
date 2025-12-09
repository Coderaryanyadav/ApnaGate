import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    
    // ONLY critical initialization - everything else lazy loaded
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    // 🛡️ Wrap app with ErrorBoundary to catch all errors
    runApp(
      const ErrorBoundary(
        child: ProviderScope(child: CrescentGateApp()),
      ),
    );
    
    // Initialize everything else in background AFTER app starts
    // ignore: unawaited_futures
    Future.microtask(() async {
      await AdsService.initialize();
      _initOneSignalBackground();
    });
  }, (error, stack) {
    // Log all uncaught errors
    debugPrint('🔴 Uncaught error: $error');
    debugPrint('Stack trace: $stack');
    // TODO: Send to crash reporting service (Sentry/Firebase Crashlytics)
  });
}

Future<void> _initOneSignalBackground() async {
  try {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose); // Changed to verbose for debugging
    OneSignal.initialize('5e9deb0b-b39a-4259-ae19-5f9d05840b03');
    
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
      'crescent_bg_service',
      'Background Monitor',
      description: 'Keeps the app running to listen for doorbell',
      importance: Importance.low, // Silent, minified
      playSound: false,
      showBadge: false,
    );

    // 🔔 2. Force High Priority Channel for Sound
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'crescent_gate_alarm_v2', // Updated to v2 to force config refresh
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
    await androidPlugin?.createNotificationChannel(channel);        // Create Loud

    // Force notification to show in foreground with Sound
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // 🔊 Manual Sound Trigger for extra loudness (if asset exists)
      // final player = AudioPlayer();
      // player.play(AssetSource('sounds/alarm.mp3'));
      
      event.notification.display();
    });
  } catch (e) {
    // Silent fail
    debugPrint('OneSignal init error: $e');
  }
}
