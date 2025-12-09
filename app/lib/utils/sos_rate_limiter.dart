import 'package:shared_preferences/shared_preferences.dart';

class SOSRateLimiter {
  static const String _lastSOSKey = 'last_sos_timestamp';
  static const int _cooldownMinutes = 5;

  static Future<bool> canSendSOS() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSOS = prefs.getInt(_lastSOSKey);
    
    if (lastSOS == null) return true;
    
    final lastSOSTime = DateTime.fromMillisecondsSinceEpoch(lastSOS);
    final now = DateTime.now();
    final difference = now.difference(lastSOSTime);
    
    return difference.inMinutes >= _cooldownMinutes;
  }

  static Future<int> getRemainingCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSOS = prefs.getInt(_lastSOSKey);
    
    if (lastSOS == null) return 0;
    
    final lastSOSTime = DateTime.fromMillisecondsSinceEpoch(lastSOS);
    final now = DateTime.now();
    final difference = now.difference(lastSOSTime);
    final remaining = _cooldownMinutes - difference.inMinutes;
    
    return remaining > 0 ? remaining : 0;
  }

  static Future<void> recordSOS() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSOSKey, DateTime.now().millisecondsSinceEpoch);
  }
}
