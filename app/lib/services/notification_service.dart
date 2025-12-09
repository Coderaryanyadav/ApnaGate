import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// 🔔 Notification Service - Secure Implementation
/// Uses environment variables for API keys

class NotificationService {
  static final String _oneSignalRestApiKey = SupabaseConfig.oneSignalRestApiKey;
  static const String _oneSignalAppId = SupabaseConfig.oneSignalAppId;
  static const String _baseUrl = 'https://onesignal.com/api/v1/notifications';

  Future<void> notifyUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    bool isSilent = false, // Added parameter
  }) async {
    try {
      // First, get the OneSignal Player ID from the database
      debugPrint('🔍 Looking up Player ID for user: $userId');
      final supabase = Supabase.instance.client;
      final profile = await supabase
          .from('profiles')
          .select('onesignal_player_id, name')
          .eq('id', userId)
          .maybeSingle();
      
      debugPrint('🔍 Profile found: ${profile?['name']}, Player ID: ${profile?['onesignal_player_id']}');
      
      final playerId = profile?['onesignal_player_id'];

      
      if (playerId == null) {
        debugPrint('❌ No OneSignal Player ID found for user $userId');
        return;
      }
      
      final body = {
        'app_id': _oneSignalAppId,
        // Use player IDs instead of external user IDs
        'include_player_ids': [playerId],
        'headings': {'en': title},
        'contents': {'en': message},
        'priority': isSilent ? 5 : 10,
        'ttl': 3600,
        'data': data ?? {},
      };

      if (!isSilent) {
        body['ios_sound'] = 'notification.wav';
        body['android_sound'] = 'notification';
        body['android_channel_id'] = 'high_importance_channel_v2'; // Match local channel
        body['content_available'] = true; // Wake up iOS app
        body['mutable_content'] = true; // Allow media
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _oneSignalRestApiKey.startsWith('os_v2_') 
              ? 'Key $_oneSignalRestApiKey' 
              : 'Basic $_oneSignalRestApiKey',
        },
        body: jsonEncode(body),
      );

      debugPrint('📡 OneSignal Response for $userId: ${response.statusCode}');
      debugPrint('📡 Response Body: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('❌ OneSignal Error for $userId: ${response.body}');
      } else {
        final responseData = jsonDecode(response.body);
        final recipients = responseData['recipients'] ?? 0;
        debugPrint('✅ OneSignal sent to $recipients recipient(s) for user $userId');
      }
    } catch (e) {
      debugPrint('❌ Notification Exception for $userId: $e');
    }
  }

  /// Send notification to all users with specific tag (e.g., all guards)
  Future<void> notifyByTag({
    required String tagKey,
    required String tagValue,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    bool isSilent = false,
  }) async {  
    try {
      final body = {
        'app_id': _oneSignalAppId,
        'filters': [
          {'field': 'tag', 'key': tagKey, 'relation': '=', 'value': tagValue}
        ],
        'headings': {'en': title},
        'contents': {'en': message},
        'priority': isSilent ? 5 : 10,
        'ttl': 3600,
        'data': data ?? {},
      };

      if (!isSilent) {
        body['ios_sound'] = 'notification.wav';
        body['android_sound'] = 'notification';
        body['android_channel_id'] = 'high_importance_channel_v2'; // Restored for SOS
        body['content_available'] = true;
        body['mutable_content'] = true;
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _oneSignalRestApiKey.startsWith('os_v2_') 
              ? 'Key $_oneSignalRestApiKey' 
              : 'Basic $_oneSignalRestApiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint('OneSignal Error: ${response.body}');
      } else {
        debugPrint('✅ Notification sent to tag: $tagKey=$tagValue (Silent: $isSilent)');
      }
    } catch (e) {
      debugPrint('❌ Notification Error: $e');
    }
  }

  /// Notify specific flat (wing + flat number)
  /// Uses BOTH OneSignal AND Supabase Realtime for guaranteed delivery
  Future<void> notifyFlat({
    required String wing,
    required String flatNumber,
    required String title,
    required String message,
    String? visitorId, // ✅ Added optional parameter
  }) async {
    try {
      // Query database for all users in this flat
      final supabase = Supabase.instance.client;
      final usersResponse = await supabase
          .from('profiles')
          .select('id, name')
          .eq('wing', wing.toUpperCase())
          .eq('flat_number', flatNumber.toUpperCase());
      
      final users = usersResponse as List<dynamic>;
      
      if (users.isEmpty) return;
      
      // Send notification to each user using BOTH methods
      for (var user in users) {
        try {
          // Method 1: Try OneSignal (best for push notifications)
          try {
            await notifyUser(
              userId: user['id'],
              title: title,
              message: message,
              data: visitorId != null ? {'visitor_id': visitorId} : null,
            );
          } catch (_) {}
          
          // Method 2: ALWAYS use Supabase Realtime (guaranteed delivery)
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
          
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('❌ Notification Error: $e');
    }
  }

  /// Smart notification: Notify tenants if present, otherwise notify owners
  Future<void> notifyVisitorArrival({
    required String residentId,
    required String visitorName,
    required String flatNumber,
    required String wing,
    String visitorId = '',
  }) async {
    try {
      // Import Supabase to query profiles
      final supabase = Supabase.instance.client;
      
      // 1. Check if there are any TENANTS in this flat
      final tenantsResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('wing', wing.toUpperCase())
          .eq('flat_number', flatNumber.toUpperCase())
          .eq('user_type', 'tenant');
      
      final tenants = tenantsResponse as List<dynamic>;
      
      if (tenants.isNotEmpty) {
        // Tenants exist - notify ONLY tenants
        debugPrint('🏠 Notifying ${tenants.length} tenant(s) for $wing-$flatNumber');
        for (var tenant in tenants) {
          await notifyUser(
            userId: tenant['id'],
            title: '🔔 New Visitor!',
            message: '$visitorName is waiting at $wing-$flatNumber',
            data: {'type': 'visitor_arrival', 'visitor_id': visitorId},
          );
        }
      } else {
        // No tenants - notify ALL residents (owners + family)
        debugPrint('🏠 No tenants found, notifying all residents for $wing-$flatNumber');
        await notifyFlat(
          wing: wing,
          flatNumber: flatNumber,
          title: '🔔 New Visitor!',
          message: '$visitorName is waiting at $wing-$flatNumber',
        );
      }
    } catch (e) {
      debugPrint('❌ Smart notification error: $e');
      // Fallback to flat-wide notification
      await notifyFlat(
        wing: wing,
        flatNumber: flatNumber,
        title: '🔔 New Visitor!',
        message: '$visitorName is waiting at $wing-$flatNumber',
      );
    }
  }

  /// Notify all guards about SOS
  Future<void> notifySOSAlert({
    required String wing,
    required String flatNumber,
    required String residentName,
  }) async {
    await notifyByTag(
      tagKey: 'role',
      tagValue: 'guard',
      title: '🚨 SOS ALERT',
      message: 'EMERGENCY at $wing-$flatNumber by $residentName',
      data: {
        'type': 'sos_alert',
        'wing': wing,
        'flat_number': flatNumber,
      },
    );

    await notifyByTag(
      tagKey: 'role',
      tagValue: 'admin',
      title: '🚨 SOS ALERT',
      message: 'EMERGENCY at $wing-$flatNumber by $residentName',
      data: {
        'type': 'sos_alert',
        'wing': wing,
        'flat_number': flatNumber,
      },
    );
  }

  /// Notify resident when visitor is approved/rejected - WITH SOUND ALERT
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
        'alert': 'true', // Force alert sound
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
