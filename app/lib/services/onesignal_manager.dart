import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OneSignalManager {
  /// Syncs the OneSignal Player ID (Subscription ID) with the Supabase Database profile.
  /// Call this whenever the user is authenticated (e.g., App Start, Login).
  static Future<void> syncUser(String userId, String? existingPlayerIdInDb) async {
    try {
      debugPrint('🔔 OneSignal Manager: Starting sync for user $userId');

      // 1. Login to OneSignal (associates device with External User ID)
      await OneSignal.login(userId);
      await OneSignal.User.addAlias('external_id', userId);

      // 2. Check Permission & ID
      // We wait a brief moment to ensure SDK has latest state
      // await Future.delayed(const Duration(seconds: 2)); 

      final id = OneSignal.User.pushSubscription.id;
      final optedIn = OneSignal.User.pushSubscription.optedIn;

      debugPrint('🔔 OneSignal Status - ID: $id, OptedIn: $optedIn');

      if (id != null && id.isNotEmpty) {
        // 3. Update DB if missing or different
        if (existingPlayerIdInDb != id) {
          debugPrint('🔔 OneSignal Manager: Updating DB with new Player ID: $id');
          
          await Supabase.instance.client
              .from('profiles')
              .update({
                'onesignal_player_id': id,
              })
              .eq('id', userId);
              
          debugPrint('✅ OneSignal Manager: DB Updated Successfully');
        } else {
          debugPrint('✅ OneSignal Manager: Player ID already up to date in DB.');
        }
      } else {
        debugPrint('⚠️ OneSignal Manager: pushSubscription.id is null. User might not have accepted permissions yet.');
        // Optionally request permission again here if we want to be aggressive
      }
    } catch (e) {
      debugPrint('❌ OneSignal Manager Sync Error: $e');
    }
  }
}
