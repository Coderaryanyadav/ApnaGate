class AppConstants {
  static const String appName = 'ApnaGate';
  static const String appTagline = 'Smart Gate & Resident Security System';

  // Roles
  static const String roleResident = 'resident';
  static const String roleGuard = 'guard';
  static const String roleAdmin = 'admin';

  // Visitor Statuses
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusCompleted = 'completed';

  // Wings
  static const List<String> defaultWings = ['A', 'B', 'C', 'D'];

  // Cache Keys
  static const String userCacheBox = 'user_cache';
  static const String patrolLogsBox = 'patrol_logs';
  static const String currentUserKey = 'current_user_profile';
}
