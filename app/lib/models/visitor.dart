class Visitor {
  final String id;
  final String? residentId;
  final String wing;
  final String flatNumber;
  final String visitorName;
  final String purpose;
  final String status;
  final String? phone;
  final String? vehicleNumber;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final DateTime? approvedAt;
  final DateTime? createdAt;

  const Visitor({
    required this.id,
    this.residentId,
    required this.wing,
    required this.flatNumber,
    required this.visitorName,
    required this.purpose,
    required this.status,
    this.phone,
    this.vehicleNumber,
    this.entryTime,
    this.exitTime,
    this.approvedAt,
    this.createdAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] as String? ?? '',
      residentId: json['resident_id'] as String?,
      wing: json['wing'] as String? ?? '',
      flatNumber: json['flat_number']?.toString() ?? '',
      visitorName: json['visitor_name'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      phone: json['phone'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      entryTime: json['entry_time'] != null
          ? DateTime.tryParse(json['entry_time'].toString())
          : null,
      exitTime: json['exit_time'] != null
          ? DateTime.tryParse(json['exit_time'].toString())
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
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
      'visitor_name': visitorName,
      'purpose': purpose,
      'status': status,
      'phone': phone,
      'vehicle_number': vehicleNumber,
      'entry_time': entryTime?.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
