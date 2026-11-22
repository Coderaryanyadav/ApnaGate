import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OneSignalManager {
  static Future<void> syncUser(String userId, String? existingPlayerId) async {
    try {
      // Login user to OneSignal
      await OneSignal.login(userId);

      // Get current subscription ID
      final subscriptionId = OneSignal.User.pushSubscription.id;
      if (subscriptionId != null && subscriptionId.isNotEmpty && subscriptionId != existingPlayerId) {
        // Sync new ID to Supabase profiles
        await Supabase.instance.client
            .from('profiles')
            .update({'onesignal_player_id': subscriptionId})
            .eq('id', userId);
        debugPrint('✅ OneSignal subscription ID synced to Supabase: $subscriptionId');
      }
    } catch (e) {
      debugPrint('⚠️ OneSignalManager syncUser failed: $e');
    }
  }
}
