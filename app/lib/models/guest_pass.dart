
DateTime _parseDate(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is String) return DateTime.parse(val);
  return DateTime.now();
}

class GuestPass {
  final String id;
  final String residentId;
  final String visitorName;
  final DateTime validUntil;
  final String token;
  final String? flatNumber;
  final String? wing;
  final bool isUsed;
  final DateTime createdAt;
  final int guestCount; // Added
  final String? additionalInfo; // Added

  GuestPass({
    required this.id,
    required this.residentId,
    required this.visitorName,
    required this.validUntil,
    required this.token,
    required this.isUsed,
    required this.createdAt,
    this.flatNumber,
    this.wing,
    this.guestCount = 1,
    this.additionalInfo,
  });

  factory GuestPass.fromMap(Map<String, dynamic> data, String id) {
    // Check for joined profile data
    String? flat;
    String? wingVal;
    
    if (data['profiles'] != null && data['profiles'] is Map) {
      flat = data['profiles']['flat_number'];
      wingVal = data['profiles']['wing'];
    }

    return GuestPass(
      id: id,
      residentId: data['resident_id'] ?? data['residentId'] ?? '',
      visitorName: data['visitor_name'] ?? data['visitorName'] ?? 'Guest',
      validUntil: _parseDate(data['valid_until'] ?? data['validUntil']),
      token: data['token'] ?? '',
      isUsed: data['is_used'] ?? data['isUsed'] ?? false,
      createdAt: _parseDate(data['created_at'] ?? data['createdAt']),
      flatNumber: flat,
      wing: wingVal,
      guestCount: data['guest_count'] ?? 1,
      additionalInfo: data['additional_info'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resident_id': residentId,
      'visitor_name': visitorName,
      'valid_until': validUntil.toIso8601String(),
      'token': token,
      'is_used': isUsed,
      'created_at': createdAt.toIso8601String(),
      'guest_count': guestCount,
      'additional_info': additionalInfo,
    };
  }
}
