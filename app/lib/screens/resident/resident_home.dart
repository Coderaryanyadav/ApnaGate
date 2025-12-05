import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/extras.dart';
import '../../widgets/banner_ad_widget.dart';
import 'approval_screen.dart';
import 'visitor_history.dart';
import 'guest_pass_screen.dart';
import 'sos_screen.dart';
import 'notice_list.dart';
import 'complaint_list.dart';
import '../../models/user.dart';
import 'service_directory.dart';

class ResidentHome extends ConsumerStatefulWidget {
  const ResidentHome({super.key});

  @override
  ConsumerState<ResidentHome> createState() => _ResidentHomeState();
}

class _ResidentHomeState extends ConsumerState<ResidentHome> {
  bool _hasShownNoticePopup = false;

  @override
  void initState() {
    super.initState();
    // Show latest notice popup after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLatestNotice();
    });
  }

  Future<void> _checkAndShowLatestNotice() async {
    if (_hasShownNoticePopup) return;
    
    try {
      final notices = await ref.read(firestoreServiceProvider).getNotices().first;
      
      if (notices.isNotEmpty && mounted) {
        _hasShownNoticePopup = true;
        final latestNotice = notices.first;
        
        _showNoticePopup(latestNotice);
      }
    } catch (e) {
      // Silently fail if no notices
    }
  }

  void _showNoticePopup(Notice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              notice.type == 'alert' ? Icons.warning : Icons.announcement,
              color: notice.type == 'alert' ? Colors.orange : Colors.indigo,
            ),
            const SizedBox(width: 8),
            const Text('New Notice'),
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
            Text(notice.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeListScreen()));
            },
            child: const Text('View All Notices'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crescent Gate'),
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
              accountName: Text('Crescent Gate', style: TextStyle(color: Colors.white)),
              accountEmail: Text('Resident Portal', style: TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.home, color: Colors.white)),
            ),
             ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<AppUser?>(
                    future: ref.read(firestoreServiceProvider).getUser(ref.read(authServiceProvider).currentUser!.uid),
                    builder: (context, snapshot) {
                      final name = snapshot.data?.name ?? 'Resident'; // Fallback
                      return Text(
                        'Welcome Home, $name', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
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
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalScreen())),
                      ),
                      // 2. Gate Pass
                      _DashboardCard(
                        icon: Icons.qr_code_2,
                        label: 'Gate Pass',
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuestPassScreen())),
                      ),
                      // 3. Building Notices
                      _DashboardCard(
                        icon: Icons.announcement,
                        label: 'Notices',
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeListScreen())),
                      ),
                       // 4. My Complaints
                      _DashboardCard(
                        icon: Icons.report_problem,
                        label: 'Complaints',
                        color: Colors.amber,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintListScreen())),
                      ),
                       // 5. Service Directory
                      _DashboardCard(
                        icon: Icons.handyman,
                        label: 'Services',
                        color: Colors.purple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceDirectoryScreen())),
                      ),
                      // 6. SOS (Red)
                      _DashboardCard(
                        icon: Icons.sos,
                        label: 'SOS Alert',
                        color: Colors.red,
                        isAlert: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Visitor History Link
                  ListTile(
                    tileColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.history, color: Colors.white),
                    title: const Text('View Visitor History', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorHistoryScreen())),
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
      color: isAlert ? Colors.red.withOpacity(0.2) : const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(20),
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
                color: isAlert ? Colors.red : color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isAlert ? Colors.white : color, size: 32),
            ),
            const SizedBox(height: 12),
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
