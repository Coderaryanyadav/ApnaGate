import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String type; // 'info', 'alert', 'event'
  final DateTime? expiresAt;

  Notice({
    required this.id, 
    required this.title, 
    required this.description, 
    required this.createdAt, 
    required this.type,
    this.expiresAt,
  });

  factory Notice.fromMap(Map<String, dynamic> map, String id) {
    return Notice(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      type: map['type'] ?? 'info',
      expiresAt: map['expiresAt'] != null ? (map['expiresAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
    };
  }
}

class Complaint {
  final String id;
  final String title;
  final String description;
  final String residentId;
  final String flatNumber;
  final String status; // 'open', 'in_progress', 'resolved'
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.residentId,
    required this.flatNumber,
    required this.status,
    required this.createdAt,
  });

  factory Complaint.fromMap(Map<String, dynamic> map, String id) {
    return Complaint(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      residentId: map['residentId'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'residentId': residentId,
      'flatNumber': flatNumber,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final String phone;
  final bool isVerified;
  final String status; // 'in', 'out'
  final DateTime? lastActive;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    this.isVerified = true,
    this.status = 'out',
    this.lastActive,
  });

  factory ServiceProvider.fromMap(Map<String, dynamic> map, String id) {
    return ServiceProvider(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      phone: map['phone'] ?? '',
      isVerified: map['isVerified'] ?? true,
      status: map['status'] ?? 'out',
      lastActive: map['lastActive'] != null ? (map['lastActive'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'phone': phone,
      'isVerified': isVerified,
      'status': status,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
    };
  }
}
