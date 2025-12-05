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
import 'service_directory.dart';

class ResidentHome extends ConsumerStatefulWidget {
  const ResidentHome({super.key});

  @override
  ConsumerState<ResidentHome> createState() => _ResidentHomeState();
}

class _ResidentHomeState extends ConsumerState<ResidentHome> {
  int _currentIndex = 0;
  bool _hasShownNoticePopup = false;

  final List<Widget> _screens = [
    const ApprovalScreen(),
    const VisitorHistoryScreen(),
    const GuestPassScreen(),
    const SOSScreen(),
  ];

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
              decoration: BoxDecoration(color: Colors.indigo),
              accountName: Text('Crescent Gate'),
              accountEmail: Text('Resident Portal'),
              currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.home, color: Colors.indigo)),
            ),
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('Building Notices'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeListScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('My Complaints'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintListScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.handyman),
              title: const Text('Service Directory'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceDirectoryScreen())),
            ),
            const Divider(),
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
          Expanded(child: _screens[_currentIndex]),
          const SafeArea(
            top: false,
            child: BannerAdWidget(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'Pass',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos, color: Colors.red),
            label: 'SOS',
          ),
        ],
      ),
    );
  }
}
