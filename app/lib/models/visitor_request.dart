import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorRequest {
  final String id;
  final String visitorName;
  final String visitorPhone;
  final String photoUrl;
  final String purpose;
  final String flatNumber;
  final String residentId;
  final String guardId;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? approvedAt;

  VisitorRequest({
    required this.id,
    required this.visitorName,
    required this.visitorPhone,
    required this.photoUrl,
    required this.purpose,
    required this.flatNumber,
    required this.residentId,
    required this.guardId,
    required this.status,
    required this.createdAt,
    this.approvedAt,
  });

  factory VisitorRequest.fromMap(Map<String, dynamic> data, String id) {
    return VisitorRequest(
      id: id,
      visitorName: data['visitorName'] ?? '',
      visitorPhone: data['visitorPhone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      purpose: data['purpose'] ?? '',
      flatNumber: data['flatNumber'] ?? '',
      residentId: data['residentId'] ?? '',
      guardId: data['guardId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorName': visitorName,
      'visitorPhone': visitorPhone,
      'photoUrl': photoUrl,
      'purpose': purpose,
      'flatNumber': flatNumber,
      'residentId': residentId,
      'guardId': guardId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }
  
  VisitorRequest copyWith({
    String? status,
    DateTime? approvedAt,
  }) {
    return VisitorRequest(
      id: id,
      visitorName: visitorName,
      visitorPhone: visitorPhone,
      photoUrl: photoUrl,
      purpose: purpose,
      flatNumber: flatNumber,
      residentId: residentId,
      guardId: guardId,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
