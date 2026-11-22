import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../utils/app_routes.dart';

class ResidentHome extends ConsumerWidget {
  const ResidentHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ApnaGate Resident'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.approval),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick SOS Banner
            InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.sos),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 36),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Alert guards & management immediately',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Feature Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                _buildCard(
                  context,
                  title: 'Visitor Approval',
                  subtitle: 'Pending check-ins',
                  icon: Icons.check_circle_outline,
                  color: Colors.cyan,
                  route: AppRoutes.approval,
                ),
                _buildCard(
                  context,
                  title: 'Visitor History',
                  subtitle: 'Past entries & logs',
                  icon: Icons.history,
                  color: Colors.blueAccent,
                  route: AppRoutes.visitorHistory,
                ),
                _buildCard(
                  context,
                  title: 'Guest Pass',
                  subtitle: 'Create digital invite',
                  icon: Icons.qr_code,
                  color: Colors.tealAccent,
                  route: AppRoutes.guestPass,
                ),
                _buildCard(
                  context,
                  title: 'My Passes',
                  subtitle: 'Active invitation codes',
                  icon: Icons.badge_outlined,
                  color: Colors.indigoAccent,
                  route: AppRoutes.myPass,
                ),
                _buildCard(
                  context,
                  title: 'Household',
                  subtitle: 'Family members',
                  icon: Icons.people_outline,
                  color: Colors.amberAccent,
                  route: AppRoutes.household,
                ),
                _buildCard(
                  context,
                  title: 'Daily Help',
                  subtitle: 'Maid, cook, driver',
                  icon: Icons.cleaning_services_outlined,
                  color: Colors.purpleAccent,
                  route: AppRoutes.househelp,
                ),
                _buildCard(
                  context,
                  title: 'Notice Board',
                  subtitle: 'Society updates',
                  icon: Icons.campaign_outlined,
                  color: Colors.orangeAccent,
                  route: AppRoutes.notices,
                ),
                _buildCard(
                  context,
                  title: 'Complaints',
                  subtitle: 'Report maintenance',
                  icon: Icons.report_problem_outlined,
                  color: Colors.redAccent,
                  route: AppRoutes.complaintList,
                ),
                _buildCard(
                  context,
                  title: 'Services',
                  subtitle: 'Plumber, electrician',
                  icon: Icons.handyman_outlined,
                  color: Colors.lightGreenAccent,
                  route: AppRoutes.serviceDirectory,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
