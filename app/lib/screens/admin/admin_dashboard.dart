import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../utils/app_routes.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        children: [
          _buildCard(
            context,
            title: 'User Management',
            icon: Icons.manage_accounts_outlined,
            color: Colors.cyan,
            route: AppRoutes.userManagement,
          ),
          _buildCard(
            context,
            title: 'Society Notices',
            icon: Icons.campaign_outlined,
            color: Colors.orangeAccent,
            route: AppRoutes.noticeAdmin,
          ),
          _buildCard(
            context,
            title: 'Analytics & Reports',
            icon: Icons.analytics_outlined,
            color: Colors.tealAccent,
            route: AppRoutes.analytics,
          ),
          _buildCard(
            context,
            title: 'Complaints Hub',
            icon: Icons.report_problem_outlined,
            color: Colors.redAccent,
            route: AppRoutes.complaints,
          ),
          _buildCard(
            context,
            title: 'Service Providers',
            icon: Icons.handyman_outlined,
            color: Colors.greenAccent,
            route: AppRoutes.serviceProviders,
          ),
          _buildCard(
            context,
            title: 'Patrol Logs',
            icon: Icons.verified_user_outlined,
            color: Colors.indigoAccent,
            route: AppRoutes.patrolLogs,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
