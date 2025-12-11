import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/extras.dart';
import '../../widgets/banner_ad_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // Added
import 'package:supabase_flutter/supabase_flutter.dart'; // Added
import '../../models/user.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_constants.dart';



class ResidentHome extends ConsumerStatefulWidget {
  const ResidentHome({super.key});

  @override
  ConsumerState<ResidentHome> createState() => _ResidentHomeState();
}

class _ResidentHomeState extends ConsumerState<ResidentHome> with WidgetsBindingObserver {
  static bool _hasSetupOneSignal = false;
  static bool _hasShownNoticePopupThisSession = false;
  bool _isFirstLoad = true; // Added for silent catch-up

  final Set<String> _handledNotificationIds = {}; // Local deduplication
  Timer? _refreshTimer;
  StreamSubscription? _visitorSub;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    
    // Ensure OneSignal is logged in and tags are set for the current user
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      // Wait for OneSignal to fully initialize (increased delay)
      Future.delayed(const Duration(milliseconds: 2000), () async {
        try {
          // First, ensure we have a subscription
          final subscriptionId = OneSignal.User.pushSubscription.id;
          debugPrint('🔍 Current OneSignal subscription: $subscriptionId');
          
          // CRITICAL: Use setExternalUserId instead of login for better reliability
          await OneSignal.User.addAlias('external_id', user.id);
          debugPrint('✅ OneSignal external ID set for: ${user.id}');
          
          // Also call login for backwards compatibility
          await OneSignal.login(user.id);
          debugPrint('✅ OneSignal login called for: ${user.id}');
          
          // Wait for changes to propagate
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Fetch profile and set tags
          final client = Supabase.instance.client;
          final profile = await client
              .from('profiles')
              .select('role, wing, flat_number, user_type')
              .eq('id', user.id)
              .maybeSingle();
              
          if (profile != null) {
            debugPrint('📋 Setting tags for ${profile['wing']}-${profile['flat_number']}');
            
            if (profile['role'] != null) {
              await OneSignal.User.addTagWithKey('role', profile['role'].toString().toLowerCase());
            }
            if (profile['wing'] != null) {
              await OneSignal.User.addTagWithKey('wing', profile['wing'].toString().toUpperCase());
            }
            if (profile['flat_number'] != null) {
              await OneSignal.User.addTagWithKey('flat_number', profile['flat_number'].toString().toUpperCase());
            }
            if (profile['user_type'] != null) {
              await OneSignal.User.addTagWithKey('user_type', profile['user_type'].toString().toLowerCase());
            }
            
            debugPrint('✅ All tags set successfully');
          }
        } catch (e) {
          debugPrint('❌ OneSignal setup error: $e');
        }
      });
    }
    
    WidgetsBinding.instance.addObserver(this); // Add Observer
    
    // 🔔 Listen for realtime notifications (reuse user variable from above)
    if (user != null) {
      final supabase = Supabase.instance.client;
      
      supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id) // 🔒 CRITICAL: Server-side filtering
          .order('created_at', ascending: false) // Latest first
          .limit(20) // Optimization
          .listen((data) {
             // 1. Filter Unread
            final userNotifications = data.where((n) => 
              n['read'] == false &&
              !_handledNotificationIds.contains(n['id'])
            ).toList();
            
            if (userNotifications.isNotEmpty) {
              for (var notification in userNotifications) {
                 _handledNotificationIds.add(notification['id']); // Mark handled locally
                 
                 // 2. Suppress Alerts on Startup (Silent Catch-up)
                 if (_isFirstLoad) {
                   debugPrint('🤫 Startup: Silently marking notification as read: ${notification['title']}');
                   // Just mark read, no alert
                   supabase.from('notifications').update({'read': true}).eq('id', notification['id']);
                   continue;
                 }

                // 🛑 CHECK FRESHNESS (Backup for runtime): Don't alert if older than 5 mins
                final createdAtStr = notification['created_at'];
                if (createdAtStr != null) {
                    final created = DateTime.tryParse(createdAtStr);
                    if (created != null && DateTime.now().difference(created).inMinutes > 5) {
                         supabase.from('notifications').update({'read': true}).eq('id', notification['id']);
                         continue; 
                    }
                }

                // 3. Show Alert (Runtime Only)
                 _showLocalNotification(
                  notification['title'] ?? 'New Notification',
                  notification['message'] ?? '',
                );
                
                // 4. Mark Read
                supabase
                    .from('notifications')
                    .update({'read': true})
                    .eq('id', notification['id']);
              }
            }
            // After processing first batch, disable suppression
            if (_isFirstLoad) {
               _isFirstLoad = false;
            }
          });
    }

    
    // OneSignal Setup (Once)
    if (!_hasSetupOneSignal) {
      _hasSetupOneSignal = true;
      _setupOneSignal();
    }
    
    _initLocalNotifications();
    _startBackgroundMonitor(); // Start BG Service
    
    // Global Auto-Refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
    
    // Listen for Token Refresh (Background Service Stability)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.tokenRefreshed) {
         _startBackgroundMonitor(); 
      }
    });
    
    // Setup Realtime Visitor Listener
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupVisitorListener());
    
    // Show latest notice popup after widget builds (only once per session)
    if (!_hasShownNoticePopupThisSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowLatestNotice();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove Observer
    _refreshTimer?.cancel();
    _refreshTimer = null; // Clear reference
    _visitorSub?.cancel();
    _visitorSub = null; // Clear reference
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-connect services on resume
      _setupOneSignal();
      // Ensure listener is active
      if (_visitorSub == null || _visitorSub!.isPaused) {
         _setupVisitorListener();
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: darwinSettings);
    await _localNotifications.initialize(initSettings);
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'visitor_notifications',
      'Visitor Notifications',
      channelDescription: 'Notifications for visitor arrivals',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.wav',
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
    debugPrint('🔔 Local notification shown: $title');
  }

  void _setupVisitorListener() {
    // 🛑 FOREGROUND NOTIFICATIONS DISABLED
    // We rely on background_service.dart for all visitor notifications
    // to prevent dual-alerting and hot-restart loops.
    // The background service is robust, persistent, and strict.
  }

  Future<void> _startBackgroundMonitor() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      service.invoke('start_monitoring', {
        'user_id': session.user.id,
        'token': session.accessToken,
      });
    }
  }



  Future<void> _setupOneSignal() async {
    // Run in background - don't await
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    
    await OneSignal.login(user.id);
    await OneSignal.User.addTagWithKey('role', 'resident');
    
    // Get flat number from Firestore (background task)
    // Get flat number from Firestore (background task)
    try {
      final userProfile = await ref.read(firestoreServiceProvider).getUser(user.id);
      if (userProfile != null) {
        if (userProfile.flatNumber != null && userProfile.flatNumber!.isNotEmpty) {
           await OneSignal.User.addTagWithKey('flat_number', userProfile.flatNumber!.toUpperCase());
        }
        if (userProfile.wing != null && userProfile.wing!.isNotEmpty) {
           await OneSignal.User.addTagWithKey('wing', userProfile.wing!.toUpperCase());
        }
      }
    } catch (_) {} // Silent fail
  }

  Future<void> _checkAndShowLatestNotice() async {
    if (_hasShownNoticePopupThisSession) return;
    
    try {
      final notices = await ref.read(firestoreServiceProvider).getNotices().first;
      
      if (notices.isNotEmpty && mounted) {
        _hasShownNoticePopupThisSession = true;
        final latestNotice = notices.first;
        
        // Only show if it's recent (within last 24 hours) and not expired
        final isRecent = DateTime.now().difference(latestNotice.createdAt).inHours < 24;
        final isExpired = latestNotice.expiresAt != null && latestNotice.expiresAt!.isBefore(DateTime.now());
        
        if (isRecent && !isExpired && latestNotice.type == 'alert') {
          _showNoticePopup(latestNotice);
        }
      }
    } catch (e) {
      // Silently fail if no notices
    }
  }

  void _showNoticePopup(Notice notice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: notice.type == 'alert' ? Colors.red : Colors.indigo,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (notice.type == 'alert' ? Colors.red : Colors.indigo).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notice.type == 'alert' ? Icons.warning_amber : Icons.announcement,
                color: notice.type == 'alert' ? Colors.red : Colors.indigo,
                size: 28,
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: Text(
                notice.type == 'alert' ? '⚠️ Important Alert' : '📢 New Notice',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              notice.description,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, AppRoutes.notices);
            },
            icon: const Icon(Icons.list),
            label: const Text('View All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

// ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ApnaGate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1E1E1E)), // Dark Header
              accountName: Text('ApnaGate', style: TextStyle(color: Colors.white)),
              accountEmail: Text('Resident Portal', style: TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.home, color: Colors.white)),
            ),
             ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.blue),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context);
              },
            ),
             // Household (Owner Only)
             FutureBuilder<AppUser?>(
               future: ref.read(firestoreServiceProvider).getUser(ref.read(authServiceProvider).currentUser?.id ?? ''),
               builder: (context, snapshot) {
                 final user = snapshot.data;
                 final isOwner = (user?.userType != 'family' && user?.userType != 'tenant') || user?.role == 'admin';
                 
                 if (!isOwner) return const SizedBox.shrink();

                 return ListTile(
                   leading: const Icon(Icons.family_restroom, color: Colors.pinkAccent),
                   title: const Text('Household & Family'),
                   onTap: () {
                     Navigator.pop(context);
                     Navigator.pushNamed(context, AppRoutes.household);
                   },
                 );
               }
             ),

             ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
            const Divider(color: Colors.white12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Crafted by Aryan',
                  style: TextStyle(
                    fontSize: 10, 
                    color: Colors.white38,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<AppUser?>(
        future: ref.read(firestoreServiceProvider).getUser(ref.read(authServiceProvider).currentUser!.id),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = user?.name ?? 'Resident';
          // Owner Check: If userType is NOT family/tenant, they are likely the owner (or admin)
          // Also check if they have no set userType (Main Owner often has null)
          final isOwner = (user?.userType != 'family' && user?.userType != 'tenant') || user?.role == 'admin';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Home, $name', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      const SizedBox(height: AppConstants.spacing20),
                      
                      // 6-Button Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          // 1. Approvals
                          _DashboardCard(
                            icon: Icons.check_circle_outline,
                            label: 'Approvals',
                            color: Colors.green,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.approval),
                          ),
                          // 2. Gate Pass
                          _DashboardCard(
                            icon: Icons.qr_code_2,
                            label: 'Gate Pass',
                            color: Colors.blue,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.guestPass),
                          ),
                          // 3. Building Notices
                          _DashboardCard(
                            icon: Icons.announcement,
                            label: 'Notices',
                            color: Colors.orange,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.notices),
                          ),
                          // 4. My Complaints
                          _DashboardCard(
                            icon: Icons.report_problem,
                            label: 'Complaints',
                            color: Colors.amber,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.complaintList),
                          ),
                           // 5. Service Directory
                          _DashboardCard(
                            icon: Icons.handyman,
                            label: 'Services',
                            color: Colors.purple,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDirectory),
                          ),
                          // 6. My Digital ID
                          _DashboardCard(
                            icon: Icons.badge,
                            label: 'My ID',
                            color: Colors.cyan,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.myPass),
                          ),
                          // 7. Househelp (Daily Staff) - Owner Only
                          if (isOwner)
                          _DashboardCard(
                            icon: Icons.cleaning_services,
                            label: 'Daily Help', 
                            color: Colors.tealAccent,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.househelp),
                          ),
                          // 8. SOS (Red)
                          _DashboardCard(
                            icon: Icons.sos,
                            label: 'SOS Alert',
                            color: Colors.red,
                            isAlert: true,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.sos),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacing20),
                      // Visitor History Link
                      ListTile(
                        tileColor: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: const Icon(Icons.history, color: Colors.white),
                        title: const Text('View Visitor History', style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                        onTap: () => Navigator.pushNamed(context, AppRoutes.visitorHistory),
                      ),
                    ],
                  ),
                ),
              ),
              const SafeArea(
                top: false,
                child: BannerAdWidget(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    // Note: We use the parent 'context' for ScaffoldMessenger, which is passed in.
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
                validator: (v) => v != passCtrl.text ? 'Mismatch' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(authServiceProvider).updatePassword(passCtrl.text);
                  if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                  }
                } catch (e) {
                   if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating password'), backgroundColor: Colors.red));
                   }
                }
              }
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isAlert;

  const _DashboardCard({
    required this.icon, 
    required this.label, 
    required this.color, 
    required this.onTap,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAlert ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isAlert ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAlert ? Colors.red : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isAlert ? Colors.white : color, size: 32),
            ),
            const SizedBox(height: AppConstants.spacing12),
            Text(
              label,
              style: TextStyle(
                color: isAlert ? Colors.redAccent : Colors.white70, 
                fontSize: 14, 
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}
