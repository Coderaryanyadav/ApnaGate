import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_constants.dart';

class GuardHome extends ConsumerStatefulWidget {
  const GuardHome({super.key});

  @override
  ConsumerState<GuardHome> createState() => _GuardHomeState();
}

class _GuardHomeState extends ConsumerState<GuardHome> {

  Timer? _refreshTimer;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Set<String> _handledAlerts = {};
  bool _isAlertShowing = false;
  static bool _hasSetupOneSignal = false;
  late Stream<List<Map<String, dynamic>>> _sosStream;

  @override
  void initState() {
    super.initState();
    _sosStream = ref.read(firestoreServiceProvider).getActiveSOS();
    
    // 1. OneSignal Setup (Critical for SOS)
    if (!_hasSetupOneSignal) {
      _hasSetupOneSignal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupOneSignal();
        _startBackgroundService(); // Start background monitoring for SOS
      });
    }

    // 2. Global Auto-Refresh (10s)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {}); 
    });

    // Init Local Notifications
    _initLocalNotifications(); 
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null; // Clear reference
    super.dispose();
  }

  Future<void> _initLocalNotifications() async { // Added
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: darwinSettings);
    await _localNotifications.initialize(initSettings);
  }

  Future<void> _triggerLocalSOS(Map<String, dynamic> alert) async { // Added
    const androidDetails = AndroidNotificationDetails(
      'apna_gate_alarm_v3', // Match channel used elsewhere
      'Critical Alerts',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      fullScreenIntent: true, // Make it pop
    );
    const details = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 SOS ALERT!', 
      'Emergency at ${alert['wing'] ?? 'Unknown'}-${alert['flat_number'] ?? alert['flatNumber'] ?? 'Unknown'}', 
      details,
    );
  }

  void _setupOneSignal() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    OneSignal.login(user.id);
    OneSignal.User.addTagWithKey('role', 'guard');
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (!isRunning) {
      await service.startService();
    }
    
    final session = Supabase.instance.client.auth.currentSession;
    final user = ref.read(authServiceProvider).currentUser;
    
    if (session != null && user != null) {
      service.invoke('start_monitoring', {
        'user_id': session.user.id,
        'token': session.accessToken,
        'role': user.role, // Guards get SOS monitoring
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _sosStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
           final newAlerts = snapshot.data!.where((a) => !_handledAlerts.contains(a['id'])).toList();
           if (newAlerts.isNotEmpty && !_isAlertShowing) { // Only show if not handled
             final alert = newAlerts.first;
             _handledAlerts.add(alert['id']);
             // 🚀 TRIGGER LOCAL NOTIFICATION (Backup)
             _triggerLocalSOS(alert);
             
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted) _showSOSDialog(alert);
             });
           }
        }
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: const Text('Guard Dashboard', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F10), Color(0xFF151520)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: EdgeInsets.zero,
                children: [
                  _buildGlassCard(context, 'Add Visitor', Icons.person_add, Colors.blueAccent, 
                    () => Navigator.pushNamed(context, AppRoutes.addVisitor)),
                  _buildGlassCard(context, 'Visitor Logs', Icons.history, Colors.orangeAccent, 
                    () => Navigator.pushNamed(context, AppRoutes.visitorStatus)),
                  _buildGlassCard(context, 'Scan', Icons.qr_code_scanner, Colors.greenAccent, 
                    () => Navigator.pushNamed(context, AppRoutes.scanPass)),
                  _buildGlassCard(context, 'Notices', Icons.announcement, Colors.purpleAccent, 
                    () => Navigator.pushNamed(context, AppRoutes.notices)),
                  _buildGlassCard(context, 'Directory', Icons.contact_phone, Colors.cyanAccent, 
                    () => Navigator.pushNamed(context, AppRoutes.serviceDirectory)),
                  _buildGlassCard(context, 'Daily Staff', Icons.badge, Colors.tealAccent, 
                    () => Navigator.pushNamed(context, AppRoutes.staffEntry)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSOSDialog(Map<String, dynamic> alert) {
    setState(() => _isAlertShowing = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF200000), // Deep Dark Red
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
            SizedBox(width: AppConstants.spacing8),
            Text('SOS ALERT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 24))
          ]
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EMERGENCY REPORTED', style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1)),
              const Divider(color: Colors.redAccent),
              const SizedBox(height: AppConstants.spacing12),
              Text('WING: ${alert['wing'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white70, fontSize: 20)),
              Text('FLAT: ${alert['flat_number'] ?? alert['flatNumber'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: AppConstants.spacing4),
              // Resident name might not be in payload if not sent, check notification service
              Text('Resident: ${alert['resident_name'] ?? alert['residentName'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: AppConstants.spacing16),
              const Text('Action Required Immediately.', style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                // 1. Resolve in DB
                await ref.read(firestoreServiceProvider).resolveSOS(alert['id']);

                // 2. Play Haptic
                // ignore: deprecated_member_use, unawaited_futures
                HapticFeedback.heavyImpact();

                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() => _isAlertShowing = false);
                }
              },
              child: const Text('ACKNOWLEDGE & RESPOND', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ).then((_) => setState(() => _isAlertShowing = false));
  }

  Widget _buildGlassCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.01)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
                  ],
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: AppConstants.spacing16),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
