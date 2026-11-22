class SosAlert {
  final String id;
  final String residentId;
  final String wing;
  final String flatNumber;
  final String status;
  final DateTime? createdAt;

  const SosAlert({
    required this.id,
    required this.residentId,
    required this.wing,
    required this.flatNumber,
    required this.status,
    this.createdAt,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      id: json['id'] as String? ?? '',
      residentId: json['resident_id'] as String? ?? '',
      wing: json['wing'] as String? ?? '',
      flatNumber: json['flat_number']?.toString() ?? '',
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
      'wing': wing,
      'flat_number': flatNumber,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
