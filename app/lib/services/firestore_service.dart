import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/visitor.dart';
import '../models/guest_pass.dart';
import '../models/daily_help.dart';
import '../models/notice.dart';
import '../models/complaint.dart';
import '../models/sos_alert.dart';
import '../models/service_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(Supabase.instance.client);
});

/// Service providing data operations with offline caching support via Hive.
class FirestoreService {
  final SupabaseClient _client;

  FirestoreService(this._client);

  // User Profile
  Future<AppUser?> getUser(String userId) async {
    try {
      // 1. Try fetching from Supabase
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final user = AppUser.fromJson(response);
        // Cache in Hive
        if (Hive.isBoxOpen('user_cache')) {
          await Hive.box('user_cache').put(userId, jsonEncode(user.toJson()));
        }
        return user;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching user from Supabase: $e');
    }

    // 2. Fallback to Hive cache
    try {
      if (Hive.isBoxOpen('user_cache')) {
        final cached = Hive.box('user_cache').get(userId);
        if (cached != null) {
          final decoded = jsonDecode(cached as String);
          return AppUser.fromJson(decoded as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error reading user from cache: $e');
    }

    return null;
  }

  Future<void> updateUser(AppUser user) async {
    await _client.from('profiles').update(user.toJson()).eq('id', user.id);
    if (Hive.isBoxOpen('user_cache')) {
      await Hive.box('user_cache').put(user.id, jsonEncode(user.toJson()));
    }
  }

  // Visitors
  Future<List<Visitor>> getVisitors({String? wing, String? flatNumber}) async {
    var query = _client.from('visitors').select();
    if (wing != null) {
      query = query.eq('wing', wing);
    }
    if (flatNumber != null) {
      query = query.eq('flat_number', flatNumber);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => Visitor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createVisitor(Visitor visitor) async {
    await _client.from('visitors').insert(visitor.toJson());
  }

  Future<void> updateVisitorStatus(String visitorId, String status) async {
    await _client.from('visitors').update({
      'status': status,
      if (status == 'approved') 'approved_at': DateTime.now().toIso8601String(),
      if (status == 'completed') 'exit_time': DateTime.now().toIso8601String(),
    }).eq('id', visitorId);
  }

  // Guest Passes
  Future<List<GuestPass>> getGuestPasses(String residentId) async {
    final response = await _client
        .from('guest_passes')
        .select()
        .eq('resident_id', residentId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => GuestPass.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createGuestPass(GuestPass pass) async {
    await _client.from('guest_passes').insert(pass.toJson());
  }

  // Notices
  Future<List<Notice>> getNotices() async {
    final response = await _client.from('notices').select().order('created_at', ascending: false);
    return (response as List).map((e) => Notice.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createNotice(Notice notice) async {
    await _client.from('notices').insert(notice.toJson());
  }

  // Complaints
  Future<List<Complaint>> getComplaints({String? residentId}) async {
    var query = _client.from('complaints').select();
    if (residentId != null) {
      query = query.eq('resident_id', residentId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => Complaint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createComplaint(Complaint complaint) async {
    await _client.from('complaints').insert(complaint.toJson());
  }

  // SOS Alerts
  Future<void> triggerSosAlert(SosAlert alert) async {
    await _client.from('sos_alerts').insert(alert.toJson());
  }

  Future<List<SosAlert>> getActiveSosAlerts() async {
    final response = await _client
        .from('sos_alerts')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (response as List).map((e) => SosAlert.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Daily Help
  Future<List<DailyHelp>> getDailyHelp({String? ownerId}) async {
    var query = _client.from('daily_help').select();
    if (ownerId != null) {
      query = query.eq('owner_id', ownerId);
    }
    final response = await query.order('name', ascending: true);
    return (response as List).map((e) => DailyHelp.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Service Providers
  Future<List<ServiceProvider>> getServiceProviders() async {
    final response = await _client.from('service_providers').select().order('category', ascending: true);
    return (response as List).map((e) => ServiceProvider.fromJson(e as Map<String, dynamic>)).toList();
  }
}
