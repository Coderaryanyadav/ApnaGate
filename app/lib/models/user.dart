import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final String? flatNumber;
  final String? wing; // 'A' or 'B'
  final String role; // 'resident', 'guard', 'admin'
  final String? userType; // 'owner' or 'renter' (for residents only)
  final String? ownerId; // If renter, reference to owner's UID
  final List<String>? familyMembers; // Names of family members
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    this.flatNumber,
    this.wing,
    required this.role,
    this.userType,
    this.ownerId,
    this.familyMembers,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      flatNumber: map['flatNumber'],
      wing: map['wing'],
      role: map['role'] ?? 'resident',
      userType: map['userType'],
      ownerId: map['ownerId'],
      familyMembers: map['familyMembers'] != null
          ? List<String>.from(map['familyMembers'])
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'flatNumber': flatNumber,
      'wing': wing,
      'role': role,
      'userType': userType,
      'ownerId': ownerId,
      'familyMembers': familyMembers,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
