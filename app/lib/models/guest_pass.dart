class GuestPass {
  final String id;
  final String residentId;
  final String guestName;
  final String? guestPhone;
  final String passCode;
  final DateTime validFrom;
  final DateTime validUntil;
  final String status;
  final DateTime? createdAt;

  const GuestPass({
    required this.id,
    required this.residentId,
    required this.guestName,
    this.guestPhone,
    required this.passCode,
    required this.validFrom,
    required this.validUntil,
    required this.status,
    this.createdAt,
  });

  factory GuestPass.fromJson(Map<String, dynamic> json) {
    return GuestPass(
      id: json['id'] as String? ?? '',
      residentId: json['resident_id'] as String? ?? '',
      guestName: json['guest_name'] as String? ?? '',
      guestPhone: json['guest_phone'] as String?,
      passCode: json['pass_code'] as String? ?? '',
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'].toString())
          : DateTime.now(),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'].toString())
          : DateTime.now().add(const Duration(days: 1)),
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resident_id': residentId,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      'pass_code': passCode,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
