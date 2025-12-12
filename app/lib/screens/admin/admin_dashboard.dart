import 'dart:async';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../services/society_config_service.dart'; // Added
import 'society_settings.dart'; // Added

import '../../utils/app_routes.dart';
import '../../utils/app_constants.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}



class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final Set<String> _handledAlerts = {};
  bool _isAlertShowing = false;
  static bool _hasSetupOneSignal = false;

  @override
  void initState() {
    super.initState();
    
    // 🔒 Security: Role Check
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authUser = ref.read(authServiceProvider).currentUser;
      
      if (authUser == null) {
        if (mounted) await Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      // 🔒 Security: Check Role from Database (More Reliable than auth metadata)
      // This also handles the case where 'user.role' extension might be missing or empty.
      final profile = await ref.read(firestoreServiceProvider).getUser(authUser.id);
      
      if (profile == null || profile.role != 'admin') {
        debugPrint('⛔ Access Denied: User ${authUser.id} is not admin. Role: ${profile?.role}');
        if (mounted) {
           await showDialog(
             context: context,
             barrierDismissible: false,
             builder: (ctx) => AlertDialog(
               title: const Text('Access Denied', style: TextStyle(color: Colors.red)),
               content: Text('You are logged in as "${profile?.role ?? 'unknown'}"\nID: ${authUser.id}\n\nThis page requires ADMIN access.'),
               actions: [
                 TextButton(
                   onPressed: () {
                     Navigator.of(ctx).pop();
                     Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                   },
                   child: const Text('Go to Login'),
                 ),
               ],
             ),
           );
        }
      }
    });
    
    // OneSignal Setup
    if (!_hasSetupOneSignal) {
      _hasSetupOneSignal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _setupOneSignal());
    }
  }

  void _setupOneSignal() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      OneSignal.login(user.id);
      OneSignal.User.addTagWithKey('role', 'admin');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _onRefresh() async {
    // Trigger rebuild to re-run FutureBuilder
    if (mounted) setState(() {});
    // Min delay to show spinner
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 Listen for SOS Alerts
    final sosStream = ref.watch(firestoreServiceProvider).getActiveSOS();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: sosStream,
      builder: (context, snapshot) {
        // Smart Alert Queueing to prevent Loop
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
           final newAlerts = snapshot.data!.where((a) => !_handledAlerts.contains(a['id'])).toList();
           
            if (newAlerts.isNotEmpty && !_isAlertShowing) {
               for (var alert in newAlerts) {
                   // 🛑 FRESHNESS CHECK (3 Minutes) - Admin Side
                   final createdAtStr = alert['created_at'];
                   if (createdAtStr != null) {
                       final created = DateTime.tryParse(createdAtStr)?.toUtc();
                       final now = DateTime.now().toUtc();
                       if (created != null && now.difference(created).inMinutes.abs() > 3) {
                          _handledAlerts.add(alert['id']);
                          continue; // Skip stale alert
                       }
                   }

                   _handledAlerts.add(alert['id']);
                   
                   // Schedule dialog to avoid build conflicts
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                     if (mounted) _showSOSDialog(alert);
                   });
                   
                   break; // Show one at a time
               }
           }
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.white,
            backgroundColor: Colors.indigo,
            child: CustomScrollView(
            slivers: [
              // 1. Modern Gradient App Bar
              SliverAppBar(
                expandedHeight: 160.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1a1a2e), // Make opaque to prevent content showing through
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin, // Keep gradient visible
                  titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
                  centerTitle: false,
                  title: const Padding(
                    padding: EdgeInsets.only(right: 60.0), // Avoid overlap with actions
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20, // Slightly smaller base size
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1a1a2e),
                          Color(0xFF16213e),
                          Color(0xFF0f3460),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.03),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.analytics),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
                    ),
                    tooltip: 'Analytics',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    ),
                    tooltip: 'Logout',
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // 2. Quick Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: FutureBuilder<Map<String, int>>(
                    future: ref.read(firestoreServiceProvider).getUserStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      final stats = snapshot.data!;
                      final residents = stats['residents'] ?? 0;
                      final guards = stats['guards'] ?? 0;
                      final total = stats['total'] ?? 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overview removed
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.4,
                            children: [
                              _ModernStatCard(
                                title: 'Residents',
                                value: '$residents',
                                icon: Icons.people_outline,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                              ),
                              _ModernStatCard(
                                title: 'Guards',
                                value: '$guards',
                                icon: Icons.shield_outlined,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                                ),
                              ),
                              _ModernStatCard(
                                title: 'Total Users',
                                value: '$total',
                                icon: Icons.group_outlined,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final config = ref.watch(societyConfigProvider);
                                  return _ModernStatCard(
                                    title: 'Wings',
                                    value: config.wings.join(', '),
                                    // Custom child for Wings to handle layout
                                    customChild: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          config.wings.join(', '),
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Wings',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    icon: Icons.apartment_outlined,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // 3. User Management Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _ActionTile(
                        title: 'Manage Users',
                        subtitle: 'Add/Remove Residents & Guards',
                        icon: Icons.manage_accounts,
                        colors: const [Color(0xFFfa709a), Color(0xFFfee140)],
                        onTap: () => Navigator.pushNamed(context, AppRoutes.userManagement),
                      ),
                      const SizedBox(height: 16),
                      _ActionTile(
                        title: 'Society Settings',
                        subtitle: 'Wings, Floors & Structure',
                        icon: Icons.settings_applications,
                        colors: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SocietySettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Building Management Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Building Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ModernMenuButton(
                              icon: Icons.announcement_outlined,
                              label: 'Notices',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              onTap: () => Navigator.pushNamed(context, AppRoutes.noticeAdmin),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModernMenuButton(
                              icon: Icons.report_problem_outlined,
                              label: 'Complaints',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                              ),
                              onTap: () => Navigator.pushNamed(context, AppRoutes.complaints),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModernMenuButton(
                              icon: Icons.handyman_outlined,
                              label: 'Services',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                              ),
                              onTap: () => Navigator.pushNamed(context, AppRoutes.serviceProviders),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // 5. Security & Patrol
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _ActionTile(
                    title: 'Patrol Logs',
                    subtitle: 'View Guard Patrol History & Scans',
                    icon: Icons.security,
                    colors: const [Color(0xFFff9966), Color(0xFFff5e62)],
                    onTap: () => Navigator.pushNamed(context, AppRoutes.patrolLogs),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
         ),
        );
      },
    );
  }

  void _showSOSDialog(Map<String, dynamic> alert) {
    setState(() => _isAlertShowing = true);
    // SOS REMAINS RED (Emergency) but UI can be cleaner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black, // Changed to black for contrast
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.red, width: 2), // Red border for urgency
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('SOS DETECTED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ]
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 20),
                      const SizedBox(width: AppConstants.spacing8),
                      Text(
                        'WING ${alert['wing'] ?? '?'} - FLAT ${alert['flat_number'] ?? alert['flatNumber'] ?? '?'}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacing12),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 20),
                      const SizedBox(width: AppConstants.spacing8),
                      Expanded(
                        child: Text(
                          'Resident: ${alert['residentName'] ?? 'Unknown'}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing16),
            Text(
              'Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}', 
              style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Solid Red for action
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
              child: const Text('ACKNOWLEDGE ALERT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    ).then((_) => setState(() => _isAlertShowing = false));
  }
}

// Modern Stat Card with Gradient


// Modern Menu Button
class _ModernMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ModernMenuButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final Widget? customChild;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.customChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decor
          Positioned(
            right: -20,
            top: -20,
            child: Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                customChild ?? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
