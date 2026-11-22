class DailyHelp {
  final String id;
  final String ownerId;
  final String name;
  final String role;
  final String? phone;
  final bool isInside;
  final DateTime? createdAt;

  const DailyHelp({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.role,
    this.phone,
    this.isInside = false,
    this.createdAt,
  });

  factory DailyHelp.fromJson(Map<String, dynamic> json) {
    return DailyHelp(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String?,
      isInside: json['is_inside'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'role': role,
      'phone': phone,
      'is_inside': isInside,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
