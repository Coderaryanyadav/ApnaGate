
DateTime _parseDate(dynamic val) {
  if (val == null) return DateTime(2000); // Default to old date to prevent 'fresh' loops
  if (val is String) return DateTime.tryParse(val) ?? DateTime(2000);
  return DateTime(2000);
}

class VisitorRequest {
  final String id;
  final String visitorName;
  final String visitorPhone;
  final String photoUrl;
  final String purpose;
  final String wing;
  final String flatNumber;
  final String residentId;
  final String guardId;
  String status; // Mutable for optimistic updates
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? entryTime;
  final DateTime? exitTime;

  VisitorRequest({
    required this.id,
    required this.visitorName,
    required this.visitorPhone,
    required this.photoUrl,
    required this.purpose,
    required this.wing,
    required this.flatNumber,
    required this.residentId,
    required this.guardId,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.entryTime,
    this.exitTime,
  });

  factory VisitorRequest.fromMap(Map<String, dynamic> data, String id) {
    return VisitorRequest(
      id: id,
      visitorName: data['visitor_name'] ?? data['visitorName'] ?? '',
      visitorPhone: data['visitor_phone'] ?? data['visitorPhone'] ?? '',
      photoUrl: data['photo_url'] ?? data['photoUrl'] ?? '',
      purpose: data['purpose'] ?? '',
      wing: data['wing'] ?? '',
      flatNumber: data['flat_number'] ?? data['flatNumber'] ?? '',
      residentId: data['resident_id'] ?? data['residentId'] ?? '',
      guardId: data['guard_id'] ?? data['guardId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: _parseDate(data['created_at'] ?? data['createdAt']),
      approvedAt: data['approved_at'] != null ? _parseDate(data['approved_at']) : null,
      entryTime: data['entry_time'] != null ? _parseDate(data['entry_time']) : null,
      exitTime: data['exit_time'] != null ? _parseDate(data['exit_time']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitor_name': visitorName,
      'visitor_phone': visitorPhone,
      'photo_url': photoUrl,
      'purpose': purpose,
      'wing': wing,
      'flat_number': flatNumber,
      'resident_id': residentId,
      'guard_id': guardId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'entry_time': entryTime?.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
    };
  }
  
  VisitorRequest copyWith({
    String? status,
    DateTime? approvedAt,
    DateTime? entryTime,
    DateTime? exitTime,
  }) {
    return VisitorRequest(
      id: id,
      visitorName: visitorName,
      visitorPhone: visitorPhone,
      photoUrl: photoUrl,
      purpose: purpose,
      wing: wing,
      flatNumber: flatNumber,
      residentId: residentId,
      guardId: guardId,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
    );
  }
}
