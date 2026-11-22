class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? wing;
  final String? flatNumber;
  final String? phone;
  final String? userType;
  final List<String>? familyMembers;
  final String? oneSignalPlayerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.wing,
    this.flatNumber,
    this.phone,
    this.userType,
    this.familyMembers,
    this.oneSignalPlayerId,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'resident',
      wing: json['wing'] as String?,
      flatNumber: json['flat_number']?.toString(),
      phone: json['phone'] as String?,
      userType: json['user_type'] as String?,
      familyMembers: (json['family_members'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      oneSignalPlayerId: json['onesignal_player_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'wing': wing,
      'flat_number': flatNumber,
      'phone': phone,
      'user_type': userType,
      'family_members': familyMembers,
      'onesignal_player_id': oneSignalPlayerId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? wing,
    String? flatNumber,
    String? phone,
    String? userType,
    List<String>? familyMembers,
    String? oneSignalPlayerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      wing: wing ?? this.wing,
      flatNumber: flatNumber ?? this.flatNumber,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      familyMembers: familyMembers ?? this.familyMembers,
      oneSignalPlayerId: oneSignalPlayerId ?? this.oneSignalPlayerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
