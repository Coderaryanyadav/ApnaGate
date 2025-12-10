import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/guard/guard_home.dart';
import 'screens/resident/resident_home.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/onesignal_manager.dart';

// ⚡ Cache user profile to avoid flashing/refetching on every rebuild
final userProfileProvider = FutureProvider.family<AppUser?, String>((ref, userId) {
  return ref.read(firestoreServiceProvider).getUser(userId);
});

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
        // Fetch user role (Cached)
        final userProfileAsync = ref.watch(userProfileProvider(user.id));

        return userProfileAsync.when(
          data: (appUser) {
            if (appUser == null) {
              return const LoginScreen();
            }

            // 🔔 Sync OneSignal Player ID (Fire & Forget)
            Future.microtask(() {
              OneSignalManager.syncUser(appUser.id, appUser.oneSignalPlayerId);
            });

            Widget home;
            switch (appUser.role) {
              case 'guard':
                home = const GuardHome();
                break;
              case 'admin':
                home = const AdminDashboard();
                break;
              case 'resident':
              default:
                home = const ResidentHome();
                break;
            }

            // 🛡️ Force Notifications Wrapper
            return _NotificationEnforcer(child: home);
          },
          loading: () => const Scaffold(
            backgroundColor: Colors.black, // Match theme for smoother load
            body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
          ),
          error: (e, trace) {
             debugPrint('⚠️ Profile fetch error: $e');
             // Retry button? Or just Login.
             return const LoginScreen();
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) {
        debugPrint('⚠️ Auth Error in Wrapper: $e. Redirecting to Login.');
        return const LoginScreen();
      },
    );
  }
}

class _NotificationEnforcer extends StatefulWidget {
  final Widget child;
  const _NotificationEnforcer({required this.child});

  @override
  State<_NotificationEnforcer> createState() => _NotificationEnforcerState();
}

class _NotificationEnforcerState extends State<_NotificationEnforcer> with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    // Wait a bit to ensure OneSignal is init
    await Future.delayed(const Duration(milliseconds: 500));
    
    // We assume true initially to avoid flicker if API call is slow
    bool status = OneSignal.Notifications.permission;
    
    if (!status) {
      // Try requesting again
      status = await OneSignal.Notifications.requestPermission(true);
    }

    if (mounted) {
      setState(() {
        _hasPermission = status;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_off_outlined, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Notifications Required',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To ensure the safety of your society, ApnaGate requires notifications to be enabled. We cannot alert you of visitors without this permission.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  onPressed: () async {
                    // Open settings
                    // Wait for user to come back (lifecycle listener handles the check)
                    // But we can also trigger a re-check manually after a delay
                    await OneSignal.Notifications.requestPermission(true);
                    // If that fails (user denied permanently), we might need to open settings
                    // OneSignal doesn't expose openSettings directly easily cross-platform but we rely on the prompt.
                    // Or we can use generic intent.
                    // For now, re-requesting often triggers the "Open Settings" system dialog on Android.
                  },
                  child: const Text('ENABLE NOTIFICATIONS'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
