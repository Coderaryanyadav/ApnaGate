import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import 'add_visitor.dart';
import 'visitor_status.dart';
import 'scan_pass.dart';
import '../resident/notice_list.dart';
import '../resident/service_directory.dart';
import 'staff_entry.dart';

class GuardHome extends ConsumerWidget {
  const GuardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(
              context,
              'Add Visitor',
              Icons.person_add,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddVisitorScreen()),
              ),
            ),
            _buildCard(
              context,
              'Visitor Logs',
              Icons.history,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VisitorStatusScreen()),
              ),
            ),
            _buildCard(
              context,
              'Scan Pass',
              Icons.qr_code_scanner,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanPassScreen()),
              ),
            ),
            _buildCard(
              context,
              'Notices',
              Icons.announcement,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticeListScreen()),
              ),
            ),
            _buildCard(
              context,
              'Directory',
              Icons.contact_phone,
              Colors.cyan,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServiceDirectoryScreen()),
              ),
            ),
            _buildCard(
              context,
              'Daily Staff',
              Icons.badge,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffEntryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
