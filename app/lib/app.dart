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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CrescentGateApp extends ConsumerWidget {
  const CrescentGateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Crescent Gate',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      themeMode: ThemeMode.system, // Auto-switch based on system
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }

          // Initialize Notifications in background
          Future.microtask(() {
            ref.read(notificationServiceProvider).initialize(user.uid);
          });

          // Fetch user role
          return FutureBuilder<AppUser?>(
            future: ref.watch(firestoreServiceProvider).getUser(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              final appUser = snapshot.data;
              if (appUser == null) {
                // User authenticated but no document found. 
                // In a real app, maybe redirect to onboarding or show error.
                return const LoginScreen();
              }

              switch (appUser.role) {
                case 'guard':
                  return const GuardHome();
                case 'admin':
                  return const AdminDashboard();
                case 'resident':
                default:
                  return const ResidentHome();
              }
            },
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
