import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/guard/guard_home.dart';
import 'screens/resident/resident_home.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CrescentGateApp extends ConsumerWidget {
  const CrescentGateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Crescent Gate',
      debugShowCheckedModeBanner: false, // Clean look
      
      // 🚫 DISABLE LIGHT THEME COMPLETELY
      theme: ThemeData.dark().copyWith(
        brightness: Brightness.dark,
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF000000), // PITCH BLACK for max contrast
        
        // Text Themes - FORCE WHITE
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          bodySmall: TextStyle(color: Colors.white70, fontSize: 12),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        
        // App Bar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212), // Slightly lighter than black
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        
        // Cards
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E), // Standard Dark Grey Card
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12, width: 1), // Subtle border for definition
          ),
        ),
        
        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
          ),
          prefixIconColor: Colors.white70,
          suffixIconColor: Colors.white70,
        ),
        
        
        // Bottom Sheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      
      // FORCE DARK MODE ALWAYS
      themeMode: ThemeMode.dark, 
      home: const SplashScreen(), // 🌟 Set Initial Route to Splash
    );
  }
}



