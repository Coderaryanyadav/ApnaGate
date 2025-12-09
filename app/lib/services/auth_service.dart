import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../supabase_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/error_logger.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // Added

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client.auth);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final GoTrueClient _auth;

  AuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((state) => state.session?.user);
  User? get currentUser => _auth.currentUser;



  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(email: email, password: password);
      
      if (response.user != null) {
        // ✅ 1. Check for Household Invitation (Auto-Link)
        await _checkAndLinkInvitation(response.user!);

        // ✅ 2. Set OneSignal External ID and save Player ID to database
        await OneSignal.User.addAlias('external_id', response.user!.id);
        await OneSignal.login(response.user!.id);
        
        // Get the OneSignal Player ID (subscription ID)
        final playerId = OneSignal.User.pushSubscription.id;
        debugPrint('✅ OneSignal Player ID: $playerId');
        
        // Save Player ID to database for direct notification targeting
        if (playerId != null) {
          try {
            final client = Supabase.instance.client;
            await client
                .from('profiles')
                .update({'onesignal_player_id': playerId})
                .eq('id', response.user!.id);
            debugPrint('✅ OneSignal Player ID saved to database');
          } catch (e) {
            debugPrint('❌ Error saving Player ID: $e');
          }
        }
        
        debugPrint('✅ OneSignal external ID and login set for: ${response.user!.id}');

        
        // ✅ 3. Fetch user profile from database to set OneSignal tags
        try {
          final client = Supabase.instance.client;
          final profileData = await client
              .from('profiles')
              .select('role, wing, flat_number, user_type')
              .eq('id', response.user!.id)
              .maybeSingle();
          
          if (profileData != null) {
            // Set OneSignal tags for notification filtering
            if (profileData['role'] != null) {
              await OneSignal.User.addTagWithKey('role', profileData['role'].toString().toLowerCase());
            }
            if (profileData['wing'] != null) {
              await OneSignal.User.addTagWithKey('wing', profileData['wing'].toString().toUpperCase());
              debugPrint('✅ OneSignal tag set: wing = ${profileData['wing']}');
            }
            if (profileData['flat_number'] != null) {
              await OneSignal.User.addTagWithKey('flat_number', profileData['flat_number'].toString().toUpperCase());
              debugPrint('✅ OneSignal tag set: flat_number = ${profileData['flat_number']}');
            }
            if (profileData['user_type'] != null) {
              await OneSignal.User.addTagWithKey('user_type', profileData['user_type'].toString().toLowerCase());
            }
          } else {
            debugPrint('⚠️ No profile found for user ${response.user!.id}');
          }
        } catch (e) {
          debugPrint('❌ Error setting OneSignal tags: $e');
          // Don't fail login if tag setting fails
        }
      }
      
      return response;
    } on AuthException catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Auth - Sign In');
      if (e.message.contains('AuthRetryableFetchException') || e.message.contains('connection')) {
         throw const AuthException('Network error. Please check your connection and try again.', statusCode: '503');
      }
      if (e.message.contains('invalid_grant')) {
         throw const AuthException('Invalid login credentials.', statusCode: '400');
      }
      if (e.message.contains('email_not_confirmed')) {
         throw const AuthException('Email not confirmed. Please check your inbox.', statusCode: '403');
      }
      rethrow;
    } catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Auth - Sign In Unknown');
      // Check for the specific "AuthRetryableFetchException" string in the error
      if (e.toString().contains('AuthRetryableFetchException')) {
         throw const AuthException('Network error during login. Please try again.', statusCode: '503');
      }
      rethrow;
    }
  }

  /// Checks if the user's phone or email matches an entry in household_registry
  /// If matched, updates the user's profile with the correct role, flat, wing, and owner_id
  Future<void> _checkAndLinkInvitation(User user) async {
    try {
      final client = Supabase.instance.client;
      
      // Check for invitation by email or phone
      // Note: This relies on the user having a phone set in Auth, or we assume email match
      // Ideally we check both. The household_registry has phone/email.
      
      final String? phone = user.phone;
      final String? email = user.email;

      // Find invite
      // We use 'or' query. 
      // Note: RLS needs to allow reading household_registry (we set to public read)
      final response = await client.from('household_registry')
          .select()
          .or('phone.eq.${phone ?? "000"},email.eq.${email ?? "nomatch"}')
          .eq('is_registered', false)
          .maybeSingle();

      if (response != null) {
         // Found an invite!
         final invite = response;
         
         // Update Profile
         await client.from('profiles').update({
           'role': 'resident', // They become a resident
           'user_type': invite['role'], // 'tenant' or 'family'
           'wing': invite['wing'],
           'flat_number': invite['flat_number'],
           'owner_id': invite['owner_id'],
           'name': invite['name'], // Auto-fill name if missing
         }).eq('id', user.id);

         // Mark invite as used
         await client.from('household_registry')
             .update({'is_registered': true})
             .eq('id', invite['id']);
         
         // Update Metadata effectively if needed (optional)
      }
    } on PostgrestException catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Auth - Invitation Check');
    } catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Auth - Invitation Check Unknown');
    }
  }

  Future<void> signOut() async {
    try {
      await OneSignal.logout();
    } catch (_) {} // Ignore errors
    // Stop background monitoring to prevent zombie notifications
    FlutterBackgroundService().invoke('stop_monitoring');
    await _auth.signOut();
  }
  
  // To create a user without logging out the admin, we use a direct HTTP call
  // to the Supabase Auth API. This bypasses the SDK's session management entirely.
  Future<String?> createUser(String email, String password) async {
    try {
      final url = Uri.parse('${SupabaseConfig.url}/auth/v1/signup');
      final response = await http.post(
        url,
        headers: {
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] ?? data['user']?['id']; // structure can be {id: ...} or {user: {id: ...}}
      } else {
        debugPrint('Sign up failed: ${response.body}');
        // Optional: throw generic error to show in UI
        return null; 
      }
    } on http.ClientException catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Auth - Create User HTTP');
      return null;
    } catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Auth - Create User');
      return null;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Auth - Reset Password');
      rethrow;
    }
  }
}

