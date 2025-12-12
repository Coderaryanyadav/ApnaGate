import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/extras.dart';
import '../../widgets/banner_ad_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/notification_service.dart'; // Added
import 'package:flutter_background_service/flutter_background_service.dart'; // Added
import 'package:supabase_flutter/supabase_flutter.dart'; // Added
import '../../models/user.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';



class ResidentHome extends ConsumerStatefulWidget {
  const ResidentHome({super.key});

  @override
  ConsumerState<ResidentHome> createState() => _ResidentHomeState();
}

class _ResidentHomeState extends ConsumerState<ResidentHome> with WidgetsBindingObserver {
  static bool _hasSetupOneSignal = false;
  static bool _hasShownNoticePopupThisSession = false;

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
            .listen((data) async {
             // 1. Get SharedPrefs instance (Quick access)
             final prefs = await SharedPreferences.getInstance();
             final List<String> handledList = prefs.getStringList('handled_notifications') ?? [];
             final Set<String> persistedHandledIds = handledList.toSet();

             // 2. Filter Unread
            final userNotifications = data.where((n) => 
              n['read'] == false &&
              !_handledNotificationIds.contains(n['id']) &&
              !persistedHandledIds.contains(n['id']) // Check persistent storage
            ).toList();
            
            if (userNotifications.isNotEmpty) {
              for (var notification in userNotifications) {
                 final String nId = notification['id'];
                 _handledNotificationIds.add(nId); 
                 
                 // Persist immediately to prevent future dupes
                 persistedHandledIds.add(nId);
                 await prefs.setStringList('handled_notifications', persistedHandledIds.toList());

                // 🛑 CHECK FRESHNESS V3 (Strict 3 Minute Window)
                final createdAtStr = notification['created_at'];
                if (createdAtStr != null) {
                    final created = DateTime.tryParse(createdAtStr)?.toUtc(); 
                    final now = DateTime.now().toUtc();
                    
                    if (created != null) {
                       final diffInMinutes = now.difference(created).inMinutes.abs();
                       // If older than 3 mins, ignore completely
                       if (diffInMinutes > 3) {
                           await supabase.from('notifications').update({'read': true}).eq('id', nId);
                           continue; 
                       }
                    }
                }

                // 3. Show Alert
                final bool isSOS = (notification['title'] ?? '').toString().contains('SOS') || 
                                   (notification['data'] != null && notification['data']['type'] == 'sos_alert');
                
                final bool isVisitor = (notification['data'] != null && notification['data']['type'] == 'visitor_arrival');

                // 🛑 PREVENT DUPLICATE: OneSignal handles Push. Dialog handles Foreground Visitor.
                // We only show Local Notification if it's SOS (Redundancy) or a generic system alert.
                // We do NOT show it for visitors to avoid "double ping".
                if (isSOS || !isVisitor) {
                   await _showLocalNotification(
                    notification['title'] ?? 'New Notification',
                    notification['message'] ?? '',
                    isSOS: isSOS,
                  );
                }

                // 🚀 IMMEDIATE ACTION: Show Approval Dialog if Visitor Arrival
                if (notification['data'] != null && 
                    notification['data']['type'] == 'visitor_arrival' && 
                    notification['data']['visitor_id'] != null) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                       if (mounted) {
                          _showIncomingVisitorDialog(notification['data']['visitor_id']);
                       }
                    });
                }
                
                // 4. Mark Read (Best Effort)
                // We rely on local prefs for immediate dedup
                await supabase
                    .from('notifications')
                    .update({'read': true})
                    .eq('id', nId);
              }
            }
          });
    }

    
    // 1. OneSignal Setup (Critical for SOS)
    if (!_hasSetupOneSignal) {
      _hasSetupOneSignal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupOneSignal();
        // 🗑️ AGGRESSIVE CLEANUP: Clear system tray on app open
        OneSignal.Notifications.clearAll();
        _startBackgroundMonitor(); // Start background monitoring for SOS
      });
    }
    
    _initLocalNotifications();
    
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

  Future<void> _showLocalNotification(String title, String body, {bool isSOS = false}) async {
    final androidDetails = AndroidNotificationDetails(
      isSOS ? 'sos_alerts_v2' : 'visitor_notifications',
      isSOS ? '🚨 SOS ALERTS' : 'Visitor Notifications',
      channelDescription: isSOS ? 'Emergency High Priority Alerts' : 'Notifications for visitor arrivals',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: isSOS ? const RawResourceAndroidNotificationSound('alarm') : const RawResourceAndroidNotificationSound('notification'),
      fullScreenIntent: isSOS, // 🚨 Try to wake screen for SOS
      category: isSOS ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.event,
    );
    
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: isSOS ? 'alarm.wav' : 'notification.wav', // Ensure these exist or fallback
      interruptionLevel: isSOS ? InterruptionLevel.critical : InterruptionLevel.active,
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
    debugPrint('🔔 Local notification shown (SOS: $isSOS): $title');
  }



  Future<void> _startBackgroundMonitor() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = ref.read(authServiceProvider).currentUser;
      service.invoke('start_monitoring', {
        'user_id': session.user.id,
        'token': session.accessToken,
        'role': user?.role ?? 'resident', // Pass role for SOS monitoring
      });
    }
  }



  Future<void> _setupOneSignal() async {
    // Run in background - don't await
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    
    await OneSignal.login(user.id);
    await OneSignal.User.addTagWithKey('role', 'resident');
    
    // LISTEN FOR CLICKS (Background -> Foreground transition)
    OneSignal.Notifications.addClickListener((event) {
       final data = event.notification.additionalData;
       if (data != null && data['visitor_id'] != null) {
          debugPrint('🖱️ Notification Clicked! Opening dialog for ${data['visitor_id']}');
          // Slight delay to allow app to settle
          Future.delayed(const Duration(milliseconds: 500), () {
             _showIncomingVisitorDialog(data['visitor_id']);
          });
       }
    });
    
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

  void _setupVisitorListener() {
    // 🔔 REALTIME VISITOR POPUP (Foreground Only)
    // Watches for NEW 'pending' requests that arrive while app is open.
    final myUserId = ref.read(authServiceProvider).currentUser?.id;
    if (myUserId == null) return;

    _visitorSub?.cancel(); // Cancel strict previous

    _visitorSub = Supabase.instance.client
        .from('visitor_requests')
        .stream(primaryKey: ['id'])
        .eq('resident_id', myUserId)
        .listen((List<Map<String, dynamic>> requests) {
           if (!mounted) return;
           
           for (var req in requests) {
              // 1. Status Check
              if (req['status'] != 'pending') continue;
              // 2. Freshness Check (Strict 45s)
              // We only popup for GENUINELY NEW requests.
              // Old pending requests (missed) will not auto-popup.
              final created = DateTime.tryParse(req['created_at']);
              if (created != null && DateTime.now().toUtc().difference(created.toUtc()).inSeconds.abs() < 45) {
                  // Check if we already handled this locally to be ultra-safe
                  if (!_handledNotificationIds.contains(req['id'])) {
                      _handledNotificationIds.add(req['id']);
                      debugPrint('⚡ Realtime Visitor Detected: ${req['id']}');
                      _showIncomingVisitorDialog(req['id']);
                  }
              }
           }
        });
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

  // 🚪 Visitor Approval Dialog - ROBOTIZED V2
  Future<void> _showIncomingVisitorDialog(String visitorId) async {
    // 🛡️ SECURITY CHECK: Prevent "Zombie" Dialogs
    // Check if this request is still pending. If already approved/rejected, ABORT.
    try {
      final request = await ref.read(firestoreServiceProvider).getVisitorRequestForApproval(visitorId).first;

      if (request == null) return; // Request invalid/deleted
      
      final String status = request['status'] ?? 'pending';
      if (status != 'pending') {
        debugPrint('⚠️ Request $visitorId is already $status. suppressing dialog.');
         return; 
      }
      
      // Request is valid and pending. Continue to show dialog.
      final visitorName = request['name'] ?? request['visitor_name'] ?? 'Visitor';
      final purpose = request['purpose'] ?? 'Visit';
      final photoUrl = request['photo_url'];

      if (!mounted) return;

      final bool? result = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false, // Must take action
        barrierLabel: 'Incoming Visitor',
        barrierColor: Colors.black.withValues(alpha: 0.9),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, anim1, anim2) => Container(),
        transitionBuilder: (ctx, anim1, anim2, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
            child: FadeTransition(
              opacity: anim1,
              child: AlertDialog(
                backgroundColor: const Color(0xFF1E1E2C), // Premium Dark
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Colors.indigoAccent, width: 2),
                ),
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                   width: MediaQuery.of(context).size.width * 0.85,
                   child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Image
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                              image: photoUrl != null 
                                ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover, opacity: 0.8)
                                : null
                            ),
                            child: photoUrl == null 
                              ? const Icon(Icons.person, size: 80, color: Colors.indigoAccent)
                              : null,
                          ),
                          // Overlay Gradient
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Color(0xFF1E1E2C)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            child: Text(
                              visitorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                shadows: [BoxShadow(color: Colors.black, blurRadius: 10)]
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      // Purpose
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '$purpose',
                          style: const TextStyle(color: Colors.indigoAccent, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Deny Button
                           _buildActionBtn(
                             icon: Icons.close, 
                             label: 'DENY', 
                             color: Colors.redAccent, 
                             onTap: () => Navigator.pop(ctx, false)
                          ),
                          
                          // Approve Button
                           _buildActionBtn(
                             icon: Icons.check, 
                             label: 'APPROVE', 
                             color: Colors.greenAccent, 
                             onTap: () => Navigator.pop(ctx, true)
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                   ),
                ),
              ),
            ),
          );
        },
      );
      
      if (result != null) {
        final guardId = request['guard_id'];
        await _processVisitor(visitorId, result, guardId: guardId, visitorName: visitorName);
      }
    } catch (e) {
      debugPrint('Error fetch visitor request status: $e');
    }
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
     return GestureDetector(
       onTap: onTap,
       child: Column(
         children: [
           Container(
             width: 60, height: 60,
             decoration: BoxDecoration(
               color: color.withValues(alpha: 0.2),
               shape: BoxShape.circle,
               border: Border.all(color: color, width: 2),
               boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12)]
             ),
             child: Icon(icon, color: color, size: 30),
           ),
           const SizedBox(height: 8),
           Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
         ],
       ),
     );
  }

  Future<void> _processVisitor(String id, bool approved, {String? guardId, String? visitorName}) async {
      try {
        final status = approved ? 'approved' : 'rejected';
        
        // Update DB
        await ref.read(firestoreServiceProvider).updateVisitorStatus(id, status);
        
        // 🔔 Notify Guard (if applicable)
        if (guardId != null) {
           await ref.read(notificationServiceProvider).notifyUser(
             userId: guardId,
             title: 'Visitor $status',
             message: '${visitorName ?? "Visitor"} has been $status by Resident.',
             data: {'type': 'visitor_update', 'visitor_id': id, 'status': status},
           );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Visitor $status successfully!'),
              backgroundColor: approved ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            )
          );
        }
      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
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
