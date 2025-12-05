import 'package:cloud_firestore/cloud_firestore.dart';

class GuestPass {
  final String id;
  final String residentId;
  final String visitorName; // Optional, can be "Guest"
  final DateTime validUntil;
  final String token;
  final bool isUsed;
  final DateTime createdAt;

  GuestPass({
    required this.id,
    required this.residentId,
    required this.visitorName,
    required this.validUntil,
    required this.token,
    required this.isUsed,
    required this.createdAt,
  });

  factory GuestPass.fromMap(Map<String, dynamic> data, String id) {
    return GuestPass(
      id: id,
      residentId: data['residentId'] ?? '',
      visitorName: data['visitorName'] ?? 'Guest',
      validUntil: (data['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      token: data['token'] ?? '',
      isUsed: data['isUsed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'residentId': residentId,
      'visitorName': visitorName,
      'validUntil': Timestamp.fromDate(validUntil),
      'token': token,
      'isUsed': isUsed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
