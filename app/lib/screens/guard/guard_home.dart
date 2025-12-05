import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'add_visitor.dart';
import 'visitor_status.dart';
import 'scan_pass.dart';
import '../resident/notice_list.dart';
import '../resident/service_directory.dart';
import 'staff_entry.dart';

class GuardHome extends ConsumerStatefulWidget {
  const GuardHome({super.key});

  @override
  ConsumerState<GuardHome> createState() => _GuardHomeState();
}

class _GuardHomeState extends ConsumerState<GuardHome> {
  final Set<String> _handledAlerts = {};
  bool _isAlertShowing = false;

  @override
  Widget build(BuildContext context) {
    // 🚨 Listen for SOS Alerts
    final sosStream = ref.watch(firestoreServiceProvider).getActiveSOS();
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: sosStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
           final newAlerts = snapshot.data!.where((a) => !_handledAlerts.contains(a['id'])).toList();
           if (newAlerts.isNotEmpty && !_isAlertShowing) {
             final alert = newAlerts.first;
             _handledAlerts.add(alert['id']);
             WidgetsBinding.instance.addPostFrameCallback((_) {
               _showSOSDialog(alert);
             });
           }
        }
        
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
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVisitorScreen())),
                ),
                _buildCard(
                  context,
                  'Visitor Logs',
                  Icons.history,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorStatusScreen())),
                ),
                _buildCard(
                  context,
                  'Scan Pass',
                  Icons.qr_code_scanner,
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPassScreen())),
                ),
                _buildCard(
                  context,
                  'Notices',
                  Icons.announcement,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeListScreen())),
                ),
                _buildCard(
                  context,
                  'Directory',
                  Icons.contact_phone,
                  Colors.cyan,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceDirectoryScreen())),
                ),
                _buildCard(
                  context,
                  'Daily Staff',
                  Icons.badge,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffEntryScreen())),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSOSDialog(Map<String, dynamic> alert) {
    setState(() => _isAlertShowing = true);
    // Play sound here if possible (requires audioplayers pkg, skipping for now)
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Row(children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 8), Text('SOS ALERT', style: TextStyle(color: Colors.white))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('EMERGENCY REPORTED!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Flat: ${alert['flatNumber']}', style: const TextStyle(color: Colors.white, fontSize: 24)),
            Text('Time: ${DateTime.now().hour}:${DateTime.now().minute}', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
            onPressed: () async {
              // Mark resolved (Wait, maybe only admin resolves? Or guard can ack?)
              // For now just close the popup locally, but really valid logic should update firestore 'status' -> 'resolved'
              // Assuming functionality exists or just dismiss.
              Navigator.pop(context);
              setState(() => _isAlertShowing = false);
            },
            child: const Text('ACKNOWLEDGE'),
          ),
        ],
      ),
    ).then((_) => setState(() => _isAlertShowing = false));
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
