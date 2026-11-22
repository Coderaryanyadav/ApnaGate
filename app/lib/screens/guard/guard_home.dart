import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../utils/app_routes.dart';

class GuardHome extends ConsumerWidget {
  const GuardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Gatekeeper'),
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
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildActionCard(
            context,
            title: 'Add Visitor',
            icon: Icons.person_add_alt_1,
            color: Colors.cyan,
            route: AppRoutes.addVisitor,
          ),
          _buildActionCard(
            context,
            title: 'Scan Guest Pass',
            icon: Icons.qr_code_scanner,
            color: Colors.tealAccent,
            route: AppRoutes.scanPass,
          ),
          _buildActionCard(
            context,
            title: 'Visitor Status',
            icon: Icons.badge_outlined,
            color: Colors.blueAccent,
            route: AppRoutes.visitorStatus,
          ),
          _buildActionCard(
            context,
            title: 'Staff / Daily Help',
            icon: Icons.groups_outlined,
            color: Colors.purpleAccent,
            route: AppRoutes.staffEntry,
          ),
          _buildActionCard(
            context,
            title: 'Patrol Checkpoint',
            icon: Icons.security,
            color: Colors.orangeAccent,
            route: AppRoutes.patrol,
          ),
          _buildActionCard(
            context,
            title: 'Emergency SOS',
            icon: Icons.warning_amber_rounded,
            color: Colors.redAccent,
            route: AppRoutes.sos,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
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
