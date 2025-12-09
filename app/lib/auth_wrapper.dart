import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/guard/guard_home.dart';
import 'screens/resident/resident_home.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/onesignal_manager.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }



        // Fetch user role
        return FutureBuilder<AppUser?>(
          future: ref.watch(firestoreServiceProvider).getUser(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            
            final appUser = snapshot.data;
            if (appUser == null) {
              return const LoginScreen();
            }

            // 🔔 Sync OneSignal Player ID
            // We use microtask to not block the UI build
            Future.microtask(() {
              OneSignalManager.syncUser(appUser.id, appUser.oneSignalPlayerId);
            });

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
      error: (e, trace) {
        // If session is invalid/corrupted, just show Login Screen
        debugPrint('⚠️ Auth Error in Wrapper: $e. Redirecting to Login.');
        return const LoginScreen(); 
      },
    );
  }
}
