
class AppConstants {
  // Wings Configuration
  static const List<String> wings = ['A', 'B'];
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Image Limits
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  
  // SOS Rate Limiting
  static const Duration sosRateLimitDuration = Duration(minutes: 5);
  
  // Session Timeout
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration inactivityTimeout = Duration(minutes: 30);
  
  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Cache Duration
  static const Duration imageCacheDuration = Duration(days: 7);
  
  // Notification Channel
  static const String notificationChannelId = 'crescent_gate_alarm_v1';
  static const String notificationChannelName = 'Emergency Alarms';

  // Spacing (replacing hardcoded SizedBoxes)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Animation Durations
  static const Duration animDurationShort = Duration(milliseconds: 200);
  static const Duration animDurationMedium = Duration(milliseconds: 400);
  static const Duration animDurationLong = Duration(milliseconds: 600);
}
