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
    bool isSilent = false,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // ✅ SECURE: Use Edge Function instead of local key
      await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'user',
          'userId': userId,
          'title': title,
          'message': message,
          'data': data,
          // 'isSilent': isSilent // Function needs update to support isSilent if needed
        },
      );
      
      debugPrint('✅ Notification sent to user $userId via Secure Function');
    } catch (e) {
      debugPrint('❌ Notification Failed for $userId: $e');
      debugPrint('⚠️ Ensure "send-notification" Edge Function is deployed!');
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
      
      debugPrint('✅ Notification sent to tag $tagKey=$tagValue via Secure Function');
    } catch (e) {
      debugPrint('❌ Tag Notification Failed: $e');
    }
  }

  /// Notify specific flat (wing + flat number)
  /// Uses BOTH OneSignal (via Function) AND Supabase Realtime
  Future<void> notifyFlat({
    required String wing,
    required String flatNumber,
    required String title,
    required String message,
    String? visitorId,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Method 1: Edge Function (Push)
      // We iterate in the function or send a tag-based flat notification if tags are set.
      // Ideally, residents should be tagged with "wing" and "flat_number".
      // Assuming they ARE tagged (recommended), we use type='flat'.
      // If not tagged, we must fallback to fetching users.
      // Safest approach for now: Fetch users and notify individually to match previous logic,
      // BUT we can use the loop with the secure function.
      
      final usersResponse = await supabase
          .from('profiles')
          .select('id, name')
          .eq('wing', wing.toUpperCase())
          .eq('flat_number', flatNumber.toUpperCase());
      
      final users = usersResponse as List<dynamic>;
      
      if (users.isEmpty) return;
      
      for (var user in users) {
        // Method 1: Secure Push
        await notifyUser(
          userId: user['id'],
          title: title,
          message: message,
          data: visitorId != null ? {'visitor_id': visitorId} : null,
        );

        // Method 2: Realtime Database (Guaranteed delivery history)
        try {
          await supabase.from('notifications').insert({
            'user_id': user['id'],
            'title': title,
            'message': message,
            'data': {
              'type': 'visitor_arrival', 
              'wing': wing, 
              'flat_number': flatNumber,
              if (visitorId != null) 'visitor_id': visitorId
            },
          });
        } catch (e) {
          debugPrint('realtime_error:${user['id']}:$e'); 
        }
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
      
      await supabase.functions.invoke(
        'send-notification',
        body: {
          'type': 'sos', // Requires updated function
          'wing': wing,
          'flatNumber': flatNumber,
          'title': '🚨 SOS ALERT',
          'message': 'EMERGENCY at $wing-$flatNumber by $residentName',
          'data': {
            'type': 'sos_alert',
            'wing': wing,
            'flat_number': flatNumber,
          },
        },
      );

      debugPrint('✅ SOS Alert sent to Guards & Admins via Secure Function');
    } catch (e) {
      debugPrint('❌ SOS Notification Exception: $e');
      debugPrint('⚠️ CRITICAL: Ensure "send-notification" function supports "sos" type');
    }
  }

  /// Notify resident when visitor is approved/rejected
  Future<void> notifyVisitorStatus({
    required String residentId,
    required String visitorName,
    required bool isApproved,
  }) async {
    await notifyUser(
      userId: residentId,
      title: isApproved ? '✅ Visitor Approved' : '❌ Visitor Rejected',
      message: isApproved 
          ? '$visitorName has been granted entry'
          : '$visitorName entry was declined',
      data: {
        'type': 'visitor_status', 
        'approved': isApproved,
        'alert': 'true',
      },
    );
  }

  /// 🧹 Sync Dismissal: Mark all notifications for this visitor as read for EVERYONE
  Future<void> markAllNotificationsAsReadForVisitor(String visitorId) async {
    try {
      final supabase = Supabase.instance.client;
      // This update query uses the JSON filter to find all notifications for this visitor
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('data->>visitor_id', visitorId);
          
      debugPrint('🧹 Synced dismissal: Notifications for visitor $visitorId marked as read for all users');
    } catch (e) {
      debugPrint('❌ Failed to sync dismissal: $e');
    }
  }
}
