import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/extras.dart';
import '../models/visitor_request.dart';
import 'package:uuid/uuid.dart';
import '../models/guest_pass.dart';
import '../utils/error_logger.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(Supabase.instance.client);
});

class FirestoreService {
  final SupabaseClient _client;

  FirestoreService(this._client);

  // ===========================================================================
  // 👤 USER MANAGEMENT
  // ===========================================================================

  Future<void> createUser(AppUser user) async {
    await _client.from('profiles').insert(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final box = Hive.box('user_cache');
    
    // 1. Try Network
    try {
      final response = await _client.from('profiles').select().eq('id', uid).maybeSingle();
      if (response != null) {
         // Cache
         await box.put('profile_$uid', response);
         return AppUser.fromMap(response, uid);
      }
    } catch (e) {
      debugPrint('Firestore getUser failed (Offline?): $e');
    }
    
    // 2. Fallback to Cache
    final cached = box.get('profile_$uid');
    if (cached != null) {
       debugPrint('✅ Loaded profile from cache: $uid');
       return AppUser.fromMap(Map<String, dynamic>.from(cached), uid);
    }
    
    return null;
  }

  Future<void> updateUser(AppUser user) async {
    await _client.from('profiles').update(user.toMap()).eq('id', user.id);
  }

  Future<void> updateUserPhoto(String userId, String photoUrl) async {
    await _client.from('profiles').update({'photo_url': photoUrl}).eq('id', userId);
  }

  Future<void> deleteUser(String uid) async {
    await _client.from('profiles').delete().eq('id', uid);
  }

  Stream<List<AppUser>> getAllUsers() {
    return _client.from('profiles').stream(primaryKey: ['id']).map((event) {
      return event.map((e) => AppUser.fromMap(e, e['id'])).toList();
    });
  }

  Stream<List<AppUser>> getUsersByRole(String role) {
    return _client.from('profiles').stream(primaryKey: ['id']).map((event) {
      return event
        .where((e) => e['role'] == role)
        .map((e) => AppUser.fromMap(e, e['id']))
        .toList();
    });
  }
  
  // ===========================================================================
  // 📢 NOTICES
  // ===========================================================================

  Stream<List<Notice>> getNotices() {
    return _client.from('notices')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) => event.map((e) => Notice.fromMap(e, e['id'])).toList());
  }

  Future<void> addNotice(Notice notice) async {
    final map = notice.toMap();
    map.remove('id'); 
    await _client.from('notices').insert(map);
  }

  Future<void> deleteNotice(String noticeId) async {
    await _client.from('notices').delete().eq('id', noticeId);
  }

  // ===========================================================================
  // 📂 COMPLAINTS
  // ===========================================================================

  Stream<List<Complaint>> getAllComplaints() {
    return _client.from('complaints')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) => event.map((e) => Complaint.fromMap(e, e['id'])).toList());
  }

  Stream<List<Complaint>> getUserComplaints(String userId) {
    return _client.from('complaints')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) {
          return event
            .where((e) => e['resident_id'] == userId)
            .map((e) => Complaint.fromMap(e, e['id']))
            .toList();
        });
  }

  Future<void> addComplaint(Complaint complaint) async {
    final map = complaint.toMap();
    map.remove('id');
    // Generate simple Ticket ID: #CG-{RANDOM 4 DIGITS}
    final ticketId = '#CG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    map['ticket_id'] = ticketId;
    
    await _client.from('complaints').insert(map);
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    await _client.from('complaints').update({'status': status}).eq('id', id);
  }

  /// CHAT METHODS
  Stream<List<ComplaintChat>> getComplaintChats(String complaintId) {
    return _client.from('complaint_chats')
        .stream(primaryKey: ['id'])
        .eq('complaint_id', complaintId)
        .order('created_at', ascending: true) // Oldest first
        .map((event) => event.map((e) => ComplaintChat.fromMap(e, e['id'])).toList());
  }

  Future<void> sendComplaintMessage({
      required String complaintId,
      required String? message,
      String? imageUrl,
      required String senderId,
      bool isAdmin = false,
  }) async {
      await _client.from('complaint_chats').insert({
          'complaint_id': complaintId,
          'sender_id': senderId,
          'message': message,
          'image_url': imageUrl,
          'is_admin': isAdmin,
          'created_at': DateTime.now().toIso8601String(),
      });
  }

  // ===========================================================================
  // 🛠️ SERVICE PROVIDERS
  // ===========================================================================

  Stream<List<ServiceProvider>> getServiceProviders() {
    return _client.from('service_providers')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((event) => event.map((e) => ServiceProvider.fromMap(e, e['id'])).toList());
  }

  Future<void> addServiceProvider(ServiceProvider provider) async {
    final map = provider.toMap();
    // Use the ID provided
    await _client.from('service_providers').insert(map);
  }

  Future<void> updateServiceProvider(ServiceProvider provider) async {
    await _client.from('service_providers').update(provider.toMap()).eq('id', provider.id);
  }

  Future<void> deleteServiceProvider(String providerId) async {
    await _client.from('service_providers').delete().eq('id', providerId);
  }
  
  Future<void> updateProviderStatus(String providerId, String status, {String? actorId, String? ownerId}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    // 1. Update Provider Status
    await _client.from('service_providers').update({
      'status': status,
      'last_active': now,
    }).eq('id', providerId);

    // 2. Log History
    try {
      await _client.from('staff_attendance_logs').insert({
        'staff_id': providerId,
        'owner_id': ownerId, // Use specific resident ID or null (to avoid 23503 FK error with Guard ID)
        'action': status == 'in' ? 'entry' : 'exit',
        'timestamp': now,
      });
    } catch (e) {
      debugPrint('Log Insertion Failed: $e');
      // Don't rethrow, strictly speaking. The status update succeeded. 
      // But user wants logs. If this fails, no logs.
      // However, preventing the whole operation due to Log failure is annoying.
      // We'll catch and print.
    }
  }

  // ---------------------------------------------------------------------------
  // 🚪 VISITOR REQUESTS (Specific)
  // ---------------------------------------------------------------------------
  
  Stream<Map<String, dynamic>?> getVisitorRequestForApproval(String requestId) {
    return _client
        .from('visitor_requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .map((events) => events.isNotEmpty ? events.first : null);
  }

  // ===========================================================================
  // 🚨 SOS ALERTS
  // ===========================================================================

  Future<void> sendSOS({String? wing}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final profile = await _client.from('profiles').select().eq('id', user.id).single();
    
    final residentWing = wing ?? profile['wing'] ?? 'Unknown';
    final flatNumber = profile['flat_number'] ?? 'Unknown';
    final residentName = profile['name'] ?? 'Unknown Resident';

    await _client.from('sos_alerts').insert({
      'resident_id': user.id,
      'resident_name': residentName,
      'wing': residentWing,
      'flat_number': flatNumber,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> resolveSOS(String id) async {
    await _client.from('sos_alerts').update({'status': 'resolved'}).eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> getActiveSOS() {
    return _client.from('sos_alerts')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) {
          return event
            .where((e) => e['status'] == 'active')
            .toList();
        });
  }
  
  // ===========================================================================
  // 📊 STATS
  // ===========================================================================

  // ===========================================================================
  // 📊 STATS
  // ===========================================================================

  Future<Map<String, int>> getUserStats() async {
    try {
      final residents = await _client.from('profiles').count().eq('role', 'resident');
      final guards = await _client.from('profiles').count().eq('role', 'guard');
      final total = await _client.from('profiles').count();
      
      return {
        'residents': residents,
        'guards': guards,
        'total': total,
      };
    } on PostgrestException catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Firestore - Get User Stats');
      return {'residents': 0, 'guards': 0, 'total': 0};
    } catch (e, stackTrace) {
      ErrorLogger.log(e, stackTrace: stackTrace, context: 'Firestore - Get User Stats Unknown');
      return {'residents': 0, 'guards': 0, 'total': 0};
    }
  }

  // Alias for backward compatibility
  Stream<List<VisitorRequest>> getVisitorHistoryForResident(String residentId) async* {
    // First, get the resident's wing and flat_number
    final profile = await _client
        .from('profiles')
        .select('wing, flat_number')
        .eq('id', residentId)
        .maybeSingle();
    
    if (profile == null) {
      yield [];
      return;
    }
    
    final wing = profile['wing'];
    final flatNumber = profile['flat_number'];
    
    if (wing == null || flatNumber == null) {
      yield [];
      return;
    }

    // Stream visitors matching this flat address
    yield* _client.from('visitors')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) {
          return event
            .where((e) => 
               e['wing'] == wing && 
               e['flat_number'] == flatNumber
            )
            .map((e) => VisitorRequest.fromMap(e, e['id']))
            .toList();
        });
  }
  Stream<List<VisitorRequest>> getPendingRequestsForResident(String residentId) async* {
    // First, get the resident's wing and flat_number
    final profile = await _client
        .from('profiles')
        .select('wing, flat_number')
        .eq('id', residentId)
        .maybeSingle();
    
    if (profile == null) {
      yield [];
      return;
    }
    
    final wing = profile['wing'];
    final flatNumber = profile['flat_number'];
    
    if (wing == null || flatNumber == null) {
      yield [];
      return;
    }
    
    // Stream all visitors for this flat
    yield* _client.from('visitors')
        .stream(primaryKey: ['id'])
        .map((event) {
          return event
            .where((e) => 
              e['wing'] == wing && 
              e['flat_number'] == flatNumber && 
              e['status'] == 'pending'
            )
            .map((e) => VisitorRequest.fromMap(e, e['id']))
            .toList();
        });
  }


  // ===========================================================================
  // 📝 VISITOR REQUESTS & GUEST PASS (MIGRATED)
  // ===========================================================================
  
  Future<void> createVisitorRequest(VisitorRequest request) async {
     await _client.from('visitors').insert({
       // Mapping from VisitorRequest model to visitors table
       'resident_id': request.residentId,
       'visitor_name': request.visitorName,
       'visitor_phone': request.visitorPhone, // ✅ Added
     'photo_url': request.photoUrl, // ✅ Added
     'purpose': request.purpose, // ✅ Added
     'wing': request.wing.toUpperCase(),
     'flat_number': request.flatNumber.toUpperCase(), // ✅ Standardize
     'guard_id': request.guardId, // ✅ Added
     'status': 'pending',
     'created_at': DateTime.now().toIso8601String(),
   });
}

  Stream<List<VisitorRequest>> getPendingRequests(String residentId) {
    return _client.from('visitors')
        .stream(primaryKey: ['id'])
        .map((event) {
          return event
            .where((e) => e['resident_id'] == residentId && e['status'] == 'pending')
            .map((e) => VisitorRequest.fromMap(e, e['id']))
            .toList();
        });
  }

  Stream<List<VisitorRequest>> getVisitorHistory(String residentId) {
     return _client.from('visitors')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .limit(50)
        .map((event) {
          return event
            .where((e) => e['resident_id'] == residentId)
            .map((e) => VisitorRequest.fromMap(e, e['id']))
            .toList();
        });
  }

  Stream<List<VisitorRequest>> getTodayVisitorLogs() {
     final now = DateTime.now();
     final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
     
     return _client.from('visitors')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .map((event) {
          return event
            .where((e) {
               final created = DateTime.parse(e['created_at']);
               // Simple check if created after start of today
               // Note: 'created_at' is string in Supabase
               return created.isAfter(DateTime.parse(startOfDay));
            })
            .map((e) => VisitorRequest.fromMap(e, e['id']))
            .toList();
        });
  }

  Future<void> updateVisitorStatus(String id, String status) async {
    await _client.from('visitors').update({
      'status': status,
      if (status == 'approved') 'approved_at': DateTime.now().toUtc().toIso8601String(),
      if (status == 'inside' || status == 'entered') 'entry_time': DateTime.now().toUtc().toIso8601String(),
      if (status == 'exited') 'exit_time': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // Guest Pass Methods
  Future<String> createGuestPass({
    required String residentId, 
    required String visitorName,
    DateTime? validUntil,
    int guestCount = 1,
    String? additionalInfo,
  }) async {
    final token = const Uuid().v4();
    final now = DateTime.now();
    final expiry = validUntil ?? now.add(const Duration(hours: 24));

    await _client.from('guest_passes').insert({
      'id': const Uuid().v4(),
      'resident_id': residentId,
      'visitor_name': visitorName,
      'token': token,
      'valid_until': expiry.toIso8601String(),
      'is_used': false,
      'created_at': now.toIso8601String(),
      'guest_count': guestCount,
      'additional_info': additionalInfo,
    });
    
    return token;
  }

  Future<void> markPassUsed(String id) async {
    await _client.from('guest_passes').update({
       'is_used': true,
       'used_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);

    // Fetch Pass & Resident Details
    final pass = await _client.from('guest_passes').select().eq('id', id).maybeSingle();
    
    if (pass != null) {
       final residentId = pass['resident_id'];
       final resident = await _client.from('profiles').select('wing, flat_number').eq('id', residentId).maybeSingle();
       
       // Create Visitor Log
       await _client.from('visitors').insert({
         'resident_id': residentId,
         'visitor_name': pass['visitor_name'],
         'purpose': 'Guest Pass',
         'status': 'entered',
         'wing': resident?['wing'] ?? 'UNK', // Fallback if missing
         'flat_number': resident?['flat_number'] ?? 'UNK',
         'entry_time': DateTime.now().toUtc().toIso8601String(),
         'created_at': DateTime.now().toUtc().toIso8601String(),
       });
       
       // 🔔 NOTIFY RESIDENT
     await _client.from('notifications').insert({
       'user_id': residentId,
       'title': 'Guest Arrived 🏠',
       'message': '${pass['visitor_name']} has entered using Guest Pass.',
       'data': {'type': 'visitor_entry'},
       'read': false,
       'created_at': DateTime.now().toUtc().toIso8601String(),
     });
    }
  }
  
  Future<GuestPass?> getPassByToken(String token) async {
    // Join with profiles table to get flat details
    final response = await _client
        .from('guest_passes')
        .select('*, profiles(flat_number, wing)')
        .eq('token', token)
        .maybeSingle();
    
    if (response == null) return null;
    return GuestPass.fromMap(response, response['id']);
  }

  // Aliases for Guest Pass
  Future<void> markGuestPassUsed(String id) => markPassUsed(id);
  Future<GuestPass?> getGuestPassByToken(String token) => getPassByToken(token);

  Future<List<AppUser>> getResidentsByFlat(String wing, String flat) async {
    final response = await _client.from('profiles')
        .select()
        .ilike('wing', wing) // Case Insensitive
        .ilike('flat_number', flat); // Case Insensitive
    return response.map((e) => AppUser.fromMap(e, e['id'])).toList();
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
     // Return empty stream as notifications via Supabase Realtime are different channel
     return Stream.value([]);
  }
  
  Future<void> cleanupNonEssentialUsers() async {
    final response = await _client.from('profiles').select();
    
    for (var user in response) {
      final role = user['role'] as String? ?? 'resident';
      final email = user['email'] as String? ?? '';
      final id = user['id'] as String;

      if (role == 'admin') continue;
      if (role == 'guard') continue;
      if (email == 'resident@example.com') continue; // Keep the specific demo user

      // Delete Profile
      await _client.from('profiles').delete().eq('id', id);
      
      // Attempt to delete Auth User (will likely fail if not Service Role, but worth a try)
      try {
        await _client.auth.admin.deleteUser(id);
      } catch (_) {}
    }
  }

  // ===========================================================================
  // 📊 ANALYTICS (REAL DATA)
  // ===========================================================================

  /// Get user counts by role (admin, guard, resident)
  Future<Map<String, int>> getUserCountsByRole() async {
    final response = await _client.from('profiles').select('role');
    final Map<String, int> counts = {'admin': 0, 'guard': 0, 'resident': 0};
    for (var user in response) {
      final role = user['role'] as String?;
      if (role != null && counts.containsKey(role)) {
        counts[role] = counts[role]! + 1;
      }
    }
    return counts;
  }

  /// Get total visitors count
  Future<int> getTotalVisitorsCount() async {
    final response = await _client.from('visitors').select('id');
    return response.length;
  }

  /// Get visitor counts by status
  Future<Map<String, int>> getVisitorCountsByStatus() async {
    final response = await _client.from('visitors').select('status');
    final Map<String, int> counts = {};
    for (var visitor in response) {
      final status = visitor['status'] as String? ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  /// Get daily visitor counts for last 7 days
  Future<List<Map<String, dynamic>>> getDailyVisitorCounts({int days = 7}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final response = await _client
        .from('visitors')
        .select('created_at')
        .gte('created_at', startDate.toIso8601String());
    
    // Group by date
    final Map<String, int> dailyCounts = {};
    for (var visitor in response) {
      final createdAt = DateTime.parse(visitor['created_at'] as String);
      final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
    }
    
    // Fill in missing days with 0
    final List<Map<String, dynamic>> result = [];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result.add({
        'date': dateKey,
        'count': dailyCounts[dateKey] ?? 0,
        'dayName': _getDayName(date.weekday),
      });
    }
    
    return result;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Get active SOS alerts count
  Future<int> getActiveSOSCount() async {
    final response = await _client
        .from('sos_alerts')
        .select('id')
        .eq('status', 'active');
    return response.length;
  }

  /// Get complaints count by status
  Future<Map<String, int>> getComplaintCountsByStatus() async {
    final response = await _client.from('complaints').select('status');
    final Map<String, int> counts = {};
    for (var complaint in response) {
      final status = complaint['status'] as String? ?? 'open';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  // ===========================================================================
  // 🏠 HOUSEHOLD MANAGEMENT
  // ===========================================================================

  Stream<List<Map<String, dynamic>>> getHouseholdMembers(String ownerId) {
    return _client.from('household_registry')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at')
        .map((event) => event);
  }

  Stream<List<AppUser>> getResidentsStream(String wing, String flatNumber) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((data) => data.where((item) => 
            item['wing']?.toString().toUpperCase() == wing.toUpperCase() && 
            item['flat_number']?.toString().toUpperCase() == flatNumber.toUpperCase()
        ).map((e) => AppUser.fromMap(e, e['id'])).toList());
  }

  /// Get household members by flat (wing + flat_number) - for synced view
  Stream<List<Map<String, dynamic>>> getHouseholdMembersByFlat(String wing, String flatNumber) {
    return _client
        .from('household_registry')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.where((item) => 
            item['wing']?.toString().toUpperCase() == wing.toUpperCase() && 
            item['flat_number']?.toString().toUpperCase() == flatNumber.toUpperCase()
        ).toList());
  }

  Future<void> addHouseholdMember({
    required String ownerId,
    required String name,
    required String phone,
    required String role, // 'tenant', 'family'
    required String wing,
    required String flatNumber,
    String? email,
    String? photoUrl,
    String? linkedUserId,
  }) async {
    await _client.from('household_registry').insert({
      'owner_id': ownerId,
      'name': name,
      'phone': phone,
      'role': role,
      'wing': wing.toUpperCase(),
      'flat_number': flatNumber.toUpperCase(),
      'email': email,
      'photo_url': photoUrl,
      'is_registered': linkedUserId != null, // Mark as registered if ID provided
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeHouseholdMember(String id) async {
    await _client.from('household_registry').delete().eq('id', id);
  }

  // Used when Owner creates an account for Family/Tenant directly
  Future<void> createProfileForMember({
    required String id,
    required String email,
    required String name,
    required String phone,
    required String role,
    required String wing,
    required String flatNumber,
    required String ownerId,
    String? photoUrl,
  }) async {
    // Upsert (Insert or Update) to avoid "duplicate key" if a Trigger already created the profile
    await _client.from('profiles').upsert({
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'wing': wing.toUpperCase(),
      'flat_number': flatNumber.toUpperCase(),
      'owner_id': ownerId,
      'photo_url': photoUrl,
      'created_at': DateTime.now().toIso8601String(), // This might update created_at, but acceptable 
    });
  }


  // --- HOUSEHELP / STAFF MANAGEMENT ---

  Future<void> addHousehelp({
    required String ownerId,
    required String name,
    required String role,
    String? phone,
    String? photoUrl,
  }) async {
    // Fetch owner's profile to get wing and flat_number
    final ownerProfile = await _client
        .from('profiles')
        .select('wing, flat_number')
        .eq('id', ownerId)
        .maybeSingle();
    
    if (ownerProfile == null) {
      throw Exception('Owner profile not found');
    }
    
    await _client.from('daily_help').insert({
      'owner_id': ownerId,
      'name': name,
      'role': role,
      'phone': phone,
      'photo_url': photoUrl,
      'is_present': false,
      'wing': ownerProfile['wing'],
      'flat_number': ownerProfile['flat_number'],
    });
  }

  Stream<List<Map<String, dynamic>>> getHousehelps(String ownerId) {
    return _client
        .from('daily_help')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('name', ascending: true);
  }

  /// Get househelps by flat (wing + flat_number) - for synced view
  Stream<List<Map<String, dynamic>>> getHousehelpsByFlat(String wing, String flatNumber) {
    return _client
        .from('daily_help')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((data) => data.where((item) => 
            item['wing']?.toString().toUpperCase() == wing.toUpperCase() && 
            item['flat_number']?.toString().toUpperCase() == flatNumber.toUpperCase()
        ).toList());
  }


  Future<void> deleteHousehelp(String id) async {
    try {
      // 1. Delete Logs first
      await _client.from('staff_attendance_logs').delete().eq('staff_id', id);
    } catch (e) {
      // Ignore if logs don't exist or permission denied
    }
    // 2. Delete Staff
    await _client.from('daily_help').delete().eq('id', id);
  }

  /// Get ALL househelps (For Guard to search/scan)
  Stream<List<Map<String, dynamic>>> getAllDailyHelp() {
    return _client
        .from('daily_help')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true);
  }

  Future<Map<String, dynamic>?> getHousehelpById(String id) async {
    return await _client.from('daily_help').select().eq('id', id).maybeSingle();
  }

  // Guard Logic: Mark Entry/Exit
  Future<void> toggleStaffAttendance(String staffId, String ownerId, bool isEntry) async {
    // 1. Update Status
    final Map<String, dynamic> updates = {
      'is_present': isEntry,
    };
    
    if (isEntry) {
      updates['last_entry_time'] = DateTime.now().toUtc().toIso8601String();
    } else {
      updates['last_exit_time'] = DateTime.now().toUtc().toIso8601String();
    }

    await _client.from('daily_help').update(updates).eq('id', staffId);

    // 2. Log History
    await _client.from('staff_attendance_logs').insert({
      'staff_id': staffId,
      'owner_id': ownerId,
      'action': isEntry ? 'entry' : 'exit',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    
  }

  // Get Logs
  Stream<List<Map<String, dynamic>>> getStaffLogs(String ownerId) {
    return _client
        .from('staff_attendance_logs')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('timestamp', ascending: false)
        .limit(50);
  }

  Stream<List<Map<String, dynamic>>> getLogsForStaff(String staffId) {
    return _client
        .from('staff_attendance_logs')
        .stream(primaryKey: ['id'])
        .eq('staff_id', staffId)
        .order('timestamp', ascending: false);
  }
}
