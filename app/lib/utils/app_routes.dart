class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String authWrapper = '/auth';

  // Admin
  static const String adminDashboard = '/admin';
  static const String userManagement = '/admin/users';
  static const String noticeAdmin = '/admin/notices';
  static const String analytics = '/admin/analytics';
  static const String complaints = '/admin/complaints';
  static const String serviceProviders = '/admin/providers';
  static const String patrolLogs = '/admin/patrol-logs';

  // Guard
  static const String guardHome = '/guard';
  static const String addVisitor = '/guard/add-visitor';
  static const String scanPass = '/guard/scan-pass';
  static const String visitorStatus = '/guard/visitor-status';
  static const String staffEntry = '/guard/staff-entry';
  static const String patrol = '/guard/patrol';

  // Resident
  static const String residentHome = '/resident';
  static const String approval = '/resident/approval';
  static const String visitorHistory = '/resident/history';
  static const String guestPass = '/resident/guest-pass';
  static const String myPass = '/resident/my-pass';
  static const String household = '/resident/household';
  static const String househelp = '/resident/househelp';
  static const String notices = '/resident/notices';
  static const String complaintList = '/resident/complaints';
  static const String serviceDirectory = '/resident/directory';
  static const String sos = '/resident/sos';
}
