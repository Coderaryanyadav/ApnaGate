import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'user_management.dart';
import 'notice_admin.dart';
import 'admin_extras.dart';
import 'analytics_dashboard.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 1. Modern App Bar
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
              ),
              IconButton(onPressed: () => ref.read(authServiceProvider).signOut(), icon: const Icon(Icons.logout)),
            ],
          ),

          // 2. Action Buttons (Quick Access)
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

          // 3. Building Management Menu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Building Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MenuButton(
                        icon: Icons.announcement,
                        label: 'Notices',
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeAdminScreen())),
                      ),
                      const SizedBox(width: 12),
                      _MenuButton(
                        icon: Icons.report_problem,
                        label: 'Complaints',
                        color: Colors.red,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintAdminScreen())),
                      ),
                      const SizedBox(width: 12),
                      _MenuButton(
                        icon: Icons.handyman,
                        label: 'Services',
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceAdminScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 4. Status Grid - REAL DATA FROM FIRESTORE
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
                  
                  // Get unique wings from residents
                  return FutureBuilder<List<dynamic>>(
                    future: ref.read(firestoreServiceProvider).getUniqueWings(),
                    builder: (context, wingsSnapshot) {
                      final wings = wingsSnapshot.data ?? [];
                      final wingsText = wings.isEmpty ? 'N/A' : wings.join(', ');

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _StatCard(
                            title: '🏠 Total Residents',
                            value: '$residents',
                            icon: Icons.home,
                            color: Colors.indigo,
                          ),
                          _StatCard(
                            title: '🛡️ Active Guards',
                            value: '$guards',
                            icon: Icons.security,
                            color: Colors.green,
                          ),
                          _StatCard(
                            title: '👥 Total Users',
                            value: '$total',
                            icon: Icons.people,
                            color: Colors.orange,
                          ),
                          _StatCard(
                            title: '🏢 Building Wings',
                            value: wingsText,
                            icon: Icons.apartment,
                            color: Colors.purple,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // 5. Spacer
          const SliverFillRemaining(hasScrollBody: false),
        ],
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color whiteOrDark(BuildContext context) => Theme.of(context).cardTheme.color!;
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 100, // Fixed height for consistency
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Theme.of(context).cardTheme.color, // Use Theme Color
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12, width: 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15), // Use withOpacity for now, it's fine
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                // Label removed from design based on screenshot, but let's keep it if needed or remove if clutter. 
                // The screenshot shows NO text labels inside the white squares, just icons.
                // Wait, the screenshot (image 1) shows "Manage Users & Residents" as a long button, and 3 square buttons below.
                // Those square buttons have icons but NO text labels visible inside them (just blue chat, red alert, orange hammer).
                // I will keep it icon-only if that matches the design, or ensure text is white if present.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
