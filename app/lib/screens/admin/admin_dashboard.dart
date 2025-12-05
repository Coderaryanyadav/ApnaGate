import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'user_management.dart';
import 'notice_admin.dart';
import 'admin_extras.dart';
import 'analytics_dashboard.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final Set<String> _handledAlerts = {};
  bool _isAlertShowing = false;

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
             final alert = newAlerts.first;
             _handledAlerts.add(alert['id']);
             
             // Schedule dialog to avoid build conflicts
             WidgetsBinding.instance.addPostFrameCallback((_) {
               _showSOSDialog(alert);
             });
           }
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              // 1. App Bar
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.indigo.shade800,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Colors.indigo.shade900, Colors.indigo.shade600],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsDashboard())),
                    icon: const Icon(Icons.analytics),
                    tooltip: 'Analytics',
                  ),
                  IconButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                  ),
                ],
              ),

              // 2. User Management Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_accounts, color: Colors.white),
                        SizedBox(width: 8),
                        Text('MANAGE USERS & RESIDENTS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Menu Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text('Building Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.announcement,
                              label: 'Notices',
                              color: Colors.blue,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeAdminScreen())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.report_problem,
                              label: 'Complaints',
                              color: Colors.red,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintAdminScreen())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.handyman,
                              label: 'Services',
                              color: Colors.orange,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceAdminScreen())),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 4. Statistics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: ref.read(firestoreServiceProvider).getUserStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final stats = snapshot.data!;
                      final residents = stats['residents'] ?? 0;
                      final guards = stats['guards'] ?? 0;
                      final total = stats['total'] ?? 0;
                      
                      const wingsText = 'A & B';

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _StatCard(title: 'Total Residents', value: '$residents', icon: Icons.home, color: Colors.indigo),
                          _StatCard(title: 'Active Guards', value: '$guards', icon: Icons.security, color: Colors.green),
                          _StatCard(title: 'Total Users', value: '$total', icon: Icons.people, color: Colors.orange),
                          _StatCard(title: 'Wings', value: wingsText, icon: Icons.apartment, color: Colors.purple),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SliverFillRemaining(hasScrollBody: false),
            ],
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
        backgroundColor: Colors.red[900],
        title: const Row(children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 8), Text('SOS ALERT', style: TextStyle(color: Colors.white))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EMERGENCY REPORTED', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Flat: ${alert['flatNumber']}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            if (alert['residentId'] != null) ...[
               const SizedBox(height: 8),
               Text('ID: ${alert['residentId']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Text('Time: ${DateTime.now().hour}:${DateTime.now().minute}', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isAlertShowing = false);
            },
            child: const Text('ACKNOWLEDGE'),
          ),
        ],
      ),
    ).then((_) => setState(() => _isAlertShowing = false));
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
