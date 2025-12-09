
// Helper for Supabase Dates
DateTime _parseDate(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is String) return DateTime.parse(val);
  return DateTime.now();
}

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
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']), // Handle snake_case from SQL
      type: map['type'] ?? 'info',
      expiresAt: map['expires_at'] != null ? _parseDate(map['expires_at']) : (map['expiresAt'] != null ? _parseDate(map['expiresAt']) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'expires_at': expiresAt?.toIso8601String(),
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
  final String? ticketId; // Added
  final List<String> images; // Added

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.residentId,
    required this.flatNumber,
    required this.status,
    required this.createdAt,
    this.ticketId,
    this.images = const [],
  });

  factory Complaint.fromMap(Map<String, dynamic> map, String id) {
    return Complaint(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      residentId: map['resident_id'] ?? map['residentId'] ?? '',
      flatNumber: map['flat_number'] ?? map['flatNumber'] ?? '',
      status: map['status'] ?? 'open',
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']),
      ticketId: map['ticket_id'] ?? map['ticketId'],
      images: (map['images'] is List) ? List<String>.from(map['images']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'resident_id': residentId,
      'flat_number': flatNumber,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'ticket_id': ticketId,
      'images': images,
    };
  }
}

class ComplaintChat {
  final String id;
  final String complaintId;
  final String? senderId;
  final String? message;
  final String? imageUrl;
  final bool isAdmin;
  final DateTime createdAt;

  ComplaintChat({
    required this.id,
    required this.complaintId,
    this.senderId,
    this.message,
    this.imageUrl,
    required this.isAdmin,
    required this.createdAt,
  });

  factory ComplaintChat.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintChat(
      id: id,
      complaintId: map['complaint_id'] ?? '',
      senderId: map['sender_id'],
      message: map['message'],
      imageUrl: map['image_url'],
      isAdmin: map['is_admin'] ?? false,
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaint_id': complaintId,
      'sender_id': senderId,
      'message': message,
      'image_url': imageUrl,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
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
      isVerified: map['is_verified'] ?? map['isVerified'] ?? true, // Support snake_case
      status: map['status'] ?? 'out',
      lastActive: (map['last_active'] ?? map['lastActive']) != null ? _parseDate(map['last_active'] ?? map['lastActive']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'phone': phone,
      'is_verified': isVerified,
      'status': status,
      'last_active': lastActive?.toIso8601String(),
    };
  }

  ServiceProvider copyWith({
    String? id,
    String? name,
    String? category,
    String? phone,
    bool? isVerified,
    String? status,
    DateTime? lastActive,
  }) {
    return ServiceProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
