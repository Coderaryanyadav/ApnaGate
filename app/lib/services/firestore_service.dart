import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/visitor_request.dart';
import '../models/guest_pass.dart';
import '../models/extras.dart'; // New Import

// --- PROVIDERS ---
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

// --- SERVICE ---
class FirestoreService {
  final FirebaseFirestore _firestore;

  // Collection References (Strongly Typed Helpers)
  CollectionReference<Map<String, dynamic>> get _usersRef => 
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _visitorRef => 
      _firestore.collection('visitorRequests');
  CollectionReference<Map<String, dynamic>> get _guestPassRef => 
      _firestore.collection('guestPasses');
  CollectionReference<Map<String, dynamic>> get _sosRef => 
      _firestore.collection('sosAlerts');
  CollectionReference<Map<String, dynamic>> get _notifRef => 
      _firestore.collection('notifications');

  FirestoreService(this._firestore);

  // ===========================================================================
  // 👤 USERS
  // ===========================================================================

  Future<void> createUser(AppUser user) async {
    await _usersRef.doc(user.uid).set(user.toMap());
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.runTransaction((transaction) async {
       // Optional: Clean up related data here if needed
       transaction.delete(_usersRef.doc(uid));
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists ? AppUser.fromMap(doc.data()!, doc.id) : null;
  }

  Stream<AppUser?> getUserStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) => 
        doc.exists ? AppUser.fromMap(doc.data()!, doc.id) : null);
  }

  /// Optimized: Returns stream of users filtered by role.
  /// Used for specific lists instead of dumping the whole DB.
  Stream<List<AppUser>> getUsersByRole(String role) {
    return _usersRef
        .where('role', isEqualTo: role)
        .snapshots()
        .map((s) => s.docs.map((d) => AppUser.fromMap(d.data(), d.id)).toList());
  }

  /// Kept for backward compatibility, but simplified
  Stream<List<AppUser>> getAllUsers() {
    return _usersRef.snapshots().map((s) => 
        s.docs.map((d) => AppUser.fromMap(d.data(), d.id)).toList());
  }
  
  Future<List<AppUser>> getResidentsByFlat(String wing, String flatNumber) async {
    final snapshot = await _usersRef
        .where('wing', isEqualTo: wing)
        .where('flatNumber', isEqualTo: flatNumber)
        .where('role', isEqualTo: 'resident')
        .get();
    return snapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
  }

  // ===========================================================================
  // 📝 VISITOR REQUESTS
  // ===========================================================================

  Future<void> createVisitorRequest(VisitorRequest request) async {
    final batch = _firestore.batch();
    
    // 1. Create Request
    final docRef = _visitorRef.doc(request.id);
    batch.set(docRef, request.toMap());

    // 2. Notify Resident (Batched)
    final notifRef = _notifRef.doc();
    batch.set(notifRef, {
      'type': 'visitor_request',
      'recipientId': request.residentId,
      'title': 'New Visitor',
      'body': '${request.visitorName} is at the gate.',
      'requestId': request.id,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    await batch.commit();
  }

  Stream<List<VisitorRequest>> getPendingRequestsForResident(String residentId) {
    return _visitorRef
        .where('residentId', isEqualTo: residentId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => VisitorRequest.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<VisitorRequest>> getVisitorHistoryForResident(String residentId) {
    return _visitorRef
        .where('residentId', isEqualTo: residentId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Performance: Limit history
        .snapshots()
        .map((s) => s.docs.map((d) => VisitorRequest.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<VisitorRequest>> getTodayVisitorLogs() {
    // Ideally filter by date range here, but `limit(50)` is a decent safe-guard
    return _visitorRef
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => VisitorRequest.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateVisitorStatus(String requestId, String status) async {
    final doc = await _visitorRef.doc(requestId).get();
    if (!doc.exists) return;
    
    final request = VisitorRequest.fromMap(doc.data()!, doc.id);
    final batch = _firestore.batch();

    // 1. Update Status
    batch.update(_visitorRef.doc(requestId), {
      'status': status,
      'approvedAt': status == 'approved' ? FieldValue.serverTimestamp() : null,
    });

    // 2. Notify Guard
    batch.set(_notifRef.doc(), {
      'type': 'visitor_update',
      'recipientId': request.guardId,
      'title': 'Visitor Update',
      'body': '${request.visitorName} has been ${status.toUpperCase()}',
      'requestId': requestId,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    await batch.commit();
  }

  // ===========================================================================
  // 🎫 GUEST PASS
  // ===========================================================================

  Future<void> createGuestPass(GuestPass pass) async {
    await _guestPassRef.doc(pass.id).set(pass.toMap());
  }

  Future<GuestPass?> getGuestPassByToken(String token) async {
    final s = await _guestPassRef.where('token', isEqualTo: token).limit(1).get();
    if (s.docs.isNotEmpty) {
      return GuestPass.fromMap(s.docs.first.data(), s.docs.first.id);
    }
    return null;
  }

  Future<void> markGuestPassUsed(String passId) async {
    await _guestPassRef.doc(passId).update({'isUsed': true});
  }

  // ===========================================================================
  // 🚨 SOS
  // ===========================================================================

  Future<void> sendSOS(String residentId, String flatNumber) async {
    // 1. Create SOS Alert
    await _sosRef.add({
      'residentId': residentId,
      'flatNumber': flatNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    // 2. Broadcast to Guards & Admins
    // Performance Fix: Using Batched Writes
    // Note: If users > 500, this needs chunking. Assuming small building (<500 staff)
    
    final staffSnapshot = await _usersRef
        .where('role', whereIn: ['guard', 'admin'])
        .get();

    final batch = _firestore.batch();
    
    for (var doc in staffSnapshot.docs) {
      final notifRef = _notifRef.doc();
      batch.set(notifRef, {
        'type': 'sos_alert',
        'recipientId': doc.id,
        'title': '🚨 SOS ALERT',
        'body': 'Emergency at Flat $flatNumber!',
        'flatNumber': flatNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    await batch.commit();
  }

  // ===========================================================================
  // 📊 STATS (Aggregation)
  // ===========================================================================
  
  Future<Map<String, int>> getUserStats() async {
    try {
      final residentsCount = await _usersRef.where('role', isEqualTo: 'resident').count().get();
      final guardsCount = await _usersRef.where('role', isEqualTo: 'guard').count().get();
      final totalUsers = await _usersRef.count().get();
      
      return {
        'residents': residentsCount.count ?? 0,
        'guards': guardsCount.count ?? 0,
        'total': totalUsers.count ?? 0,
      };
    } catch (e) {
      // debugPrint('Error fetching stats: $e');
      return {'residents': 0, 'guards': 0, 'total': 0};
    }
  }

  Future<List<String>> getUniqueWings() async {
    try {
      final snapshot = await _usersRef.where('role', isEqualTo: 'resident').get();
      final wings = <String>{};
      
      for (var doc in snapshot.docs) {
        final wing = doc.data()['wing'] as String?;
        if (wing != null && wing.isNotEmpty) {
          wings.add(wing);
        }
      }
      
      final sorted = wings.toList()..sort();
      return sorted;
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // 🔔 NOTIFICATIONS
  // ===========================================================================

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _notifRef
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ===========================================================================
  // 📢 NOTICES
  // ===========================================================================

  Stream<List<Notice>> getNotices() {
    return _firestore.collection('notices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) {
          final now = DateTime.now();
          return s.docs.map((d) => Notice.fromMap(d.data(), d.id))
            .where((n) => n.expiresAt == null || n.expiresAt!.isAfter(now))
            .toList();
        });
  }

  Future<void> addNotice(Notice notice) async {
    await _firestore.collection('notices').add(notice.toMap());
  }

  Future<void> deleteNotice(String noticeId) async {
    await _firestore.collection('notices').doc(noticeId).delete();
  }

  // ===========================================================================
  // 📂 COMPLAINTS
  // ===========================================================================

  Stream<List<Complaint>> getAllComplaints() {
    return _firestore.collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Complaint.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Complaint>> getUserComplaints(String userId) {
    return _firestore.collection('complaints')
        .where('residentId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Complaint.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addComplaint(Complaint complaint) async {
    await _firestore.collection('complaints').add(complaint.toMap());
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    await _firestore.collection('complaints').doc(id).update({'status': status});
  }

  // ===========================================================================
  // 🛠️ SERVICE PROVIDERS
  // ===========================================================================

  Stream<List<ServiceProvider>> getServiceProviders() {
    return _firestore.collection('serviceProviders')
        .orderBy('category')
        .snapshots()
        .map((s) => s.docs.map((d) => ServiceProvider.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addServiceProvider(ServiceProvider provider) async {
    await _firestore.collection('serviceProviders').add(provider.toMap());
  }

  Future<void> updateProviderStatus(String providerId, String status) async {
    final batch = _firestore.batch();
    
    // 1. Update Provider Status
    batch.update(_firestore.collection('serviceProviders').doc(providerId), {
      'status': status,
      'lastActive': FieldValue.serverTimestamp(),
    });

    // 2. Create Log
    final logRef = _firestore.collection('staffLogs').doc();
    batch.set(logRef, {
      'providerId': providerId,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> updateUser(AppUser user) async {
    await _usersRef.doc(user.uid).update(user.toMap());
  }

  Stream<List<Map<String, dynamic>>> getActiveSOS() {
    return _sosRef
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
