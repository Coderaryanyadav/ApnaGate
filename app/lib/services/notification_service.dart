import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// 🔔 Notification Service - Secure Implementation
/// Uses environment variables for API keys

class NotificationService {
  Future<void> notifyUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? channelId,
    bool isSilent = false,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      // 1. ✅ SECURE PUSH: Use Edge Function
      await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'user',
          'userId': userId,
          'title': title,
          'message': message,
          'data': data,
          if (channelId != null) 'android_channel_id': channelId,
        },
      );
      debugPrint('✅ PUSH sent to user $userId');

      // 2. ✅ REALTIME DB: Insert into notifications table (Guaranteed History & Local Alert)
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'data': data ?? {},
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ DB Insert for user $userId');

    } catch (e) {
      debugPrint('❌ Notification Failed for $userId: $e');
    }
  }

  /// Send notification to all users with specific tag (e.g., all guards)
  Future<void> notifyByTag({
    required String tagKey,
    required String tagValue,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    bool isSilent = true,
  }) async {  
    // Tag notifications are Push-Only usually, unless we fetch all users.
    // For now, keep as is (Edge Function Only).
    try {
      final supabase = Supabase.instance.client;
      await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'tag',
          'tagKey': tagKey,
          'tagValue': tagValue,
          'title': title,
          'message': message,
          'data': data,
        },
      );
      debugPrint('✅ TAG Notification sent: $tagKey=$tagValue');
    } catch (e) {
      debugPrint('❌ Tag Notification Failed: $e');
    }
  }

  /// Notify specific flat (wing + flat number)
  /// Uses CENTRALIZED notifyUser for consistent delivery
  Future<void> notifyFlat({
    required String wing,
    required String flatNumber,
    required String title,
    required String message,
    String? visitorId,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      final usersResponse = await supabase
          .from('profiles')
          .select('id, name')
          .ilike('wing', wing)
          .ilike('flat_number', flatNumber);
      
      final users = usersResponse as List<dynamic>;
      
      if (users.isEmpty) return;
      
      for (var user in users) {
        // Use the robust notifyUser (Push + DB)
        await notifyUser(
          userId: user['id'],
          title: title,
          message: message,
          data: {
            'type': 'visitor_arrival', 
            'wing': wing, 
            'flat_number': flatNumber,
            if (visitorId != null) 'visitor_id': visitorId
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Flat Notification Error: $e');
    }
  }

  /// Notify all guards and admins about SOS
  Future<void> notifySOSAlert({
    required String wing,
    required String flatNumber,
    required String residentName,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Fetch all Guards and Admins
      final recipients = await supabase
          .from('profiles')
          .select('id')
          .or('role.eq.guard,role.eq.admin');
      
      final List<dynamic> users = recipients as List<dynamic>;

      debugPrint('🚨 Sending SOS to ${users.length} guards/admins');

      for (var user in users) {
        await notifyUser(
          userId: user['id'],
          title: '🚨 SOS ALERT',
          message: 'EMERGENCY at $wing-$flatNumber by $residentName',
          data: {
            'type': 'sos_alert',
            'wing': wing,
            'flat_number': flatNumber,
            'resident_name': residentName,
          },
          channelId: 'apna_gate_alarm_v3', // 🚨 FORCE HIGH PRIORITY
        );
      }
    } catch (e) {
      debugPrint('❌ SOS Notification Exception: $e');
    }
  }

  /// Notify resident when visitor is approved/rejected
  Future<void> notifyVisitorStatus({
    required String residentId,
    required String visitorName,
    required bool isApproved,
  }) async {
    // Uses notifyUser -> Push + DB + Local Alert
    await notifyUser(
      userId: residentId,
      title: isApproved ? '✅ Visitor Approved' : '❌ Visitor Rejected',
      message: isApproved 
          ? '$visitorName has been granted entry'
          : '$visitorName entry was declined',
      data: {
        'type': 'visitor_status', 
        'approved': isApproved,
        'visitor_name': visitorName,
        'alert': 'true',
      },
    );
  }

  /// 🧹 Sync Dismissal: Mark all notifications for this visitor as read
  Future<void> markAllNotificationsAsReadForVisitor(String visitorId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('notifications')
          .update({'read': true})
          // Fix JSON filter syntax for Supabase Flutter if needed, or use a simpler approach
          // .eq('data->>visitor_id', visitorId) might fail if column is jsonb and driver is specific
          // Using containedIn for jsonb is safer if structure matches
          .contains('data', {'visitor_id': visitorId});
          
      debugPrint('🧹 Synced dismissal for $visitorId');
    } catch (e) {
      debugPrint('❌ Failed to sync dismissal: $e');
    }
  }
}
