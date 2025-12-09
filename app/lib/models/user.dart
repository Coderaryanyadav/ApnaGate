
DateTime _parseDate(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is String) return DateTime.parse(val);
  return DateTime.now();
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? flatNumber;
  final String? wing;
  final String role;
  final String? userType;
  final String? ownerId;
  final List<String>? familyMembers;
  final String? photoUrl; // Added
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.flatNumber,
    this.wing,
    required this.role,
    this.userType,
    this.ownerId,
    this.familyMembers,
    this.photoUrl,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      flatNumber: map['flat_number'] ?? map['flatNumber'],
      wing: map['wing'],
      role: map['role'] ?? 'resident',
      userType: map['user_type'] ?? map['userType'],
      ownerId: map['owner_id'] ?? map['ownerId'],
      familyMembers: (map['family_members'] ?? map['familyMembers']) != null
          ? List<String>.from(map['family_members'] ?? map['familyMembers'])
          : null,
      photoUrl: map['photo_url'],
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'flat_number': flatNumber,
      'wing': wing,
      'role': role,
      'user_type': userType,
      'owner_id': ownerId,
      'family_members': familyMembers,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? flatNumber,
    String? wing,
    String? role,
    String? userType,
    String? ownerId,
    List<String>? familyMembers,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      flatNumber: flatNumber ?? this.flatNumber,
      wing: wing ?? this.wing,
      role: role ?? this.role,
      userType: userType ?? this.userType,
      ownerId: ownerId ?? this.ownerId,
      familyMembers: familyMembers ?? this.familyMembers,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
