import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';

// Screens
import 'auth_wrapper.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/guard/staff_entry.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_extras.dart'; // Import this

import 'screens/guard/guard_home.dart';
import 'screens/resident/resident_home.dart';
import 'screens/guard/add_visitor.dart';
import 'screens/guard/scan_pass.dart';
import 'screens/guard/visitor_status.dart';
import 'screens/admin/user_management.dart';
import 'screens/admin/notice_admin.dart';
import 'screens/admin/analytics_dashboard.dart';
import 'screens/resident/approval_screen.dart';
import 'screens/resident/visitor_history.dart';
import 'screens/resident/guest_pass_screen.dart';
import 'screens/resident/my_pass.dart';
import 'screens/resident/household_screen.dart';
import 'screens/resident/househelp_screen.dart'; // Added
import 'screens/resident/notice_list.dart';
import 'screens/resident/complaint_list.dart';
import 'screens/resident/service_directory.dart';
import 'screens/resident/sos_screen.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApnaGateApp extends ConsumerWidget {
  const ApnaGateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to trigger rebuilds if necessary
    ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ApnaGate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Named Routes
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.authWrapper: (context) => const AuthWrapper(),
        
        // Admin Routes
        AppRoutes.adminDashboard: (context) => const AdminDashboard(),
        AppRoutes.userManagement: (context) => const UserManagementScreen(),
        AppRoutes.noticeAdmin: (context) => const NoticeAdminScreen(),
        AppRoutes.analytics: (context) => const AnalyticsDashboard(),
        AppRoutes.complaints: (context) => const ComplaintAdminScreen(), 
        AppRoutes.serviceProviders: (context) => const ServiceProviderAdminScreen(),
        
        // Guard Routes
        AppRoutes.guardHome: (context) => const GuardHome(),
        AppRoutes.addVisitor: (context) => const AddVisitorScreen(),
        AppRoutes.scanPass: (context) => const ScanPassScreen(),
        AppRoutes.visitorStatus: (context) => const VisitorStatusScreen(),
        AppRoutes.staffEntry: (context) => const StaffEntryScreen(),
        
        // Resident Routes
        AppRoutes.residentHome: (context) => const ResidentHome(),
        AppRoutes.approval: (context) => const ApprovalScreen(),
        AppRoutes.visitorHistory: (context) => const VisitorHistoryScreen(),
        AppRoutes.guestPass: (context) => const GuestPassScreen(),
        AppRoutes.myPass: (context) => const MyPassScreen(),
        AppRoutes.household: (context) => const HouseholdScreen(),
        AppRoutes.househelp: (context) => const HousehelpScreen(),
        AppRoutes.notices: (context) => const NoticeListScreen(),
        AppRoutes.complaintList: (context) => const ComplaintListScreen(),
        AppRoutes.serviceDirectory: (context) => const ServiceDirectoryScreen(),
        AppRoutes.sos: (context) => const SosScreen(),
      },
    );
  }
}



