class Complaint {
  final String id;
  final String residentId;
  final String title;
  final String description;
  final String status;
  final DateTime? createdAt;

  const Complaint({
    required this.id,
    required this.residentId,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String? ?? '',
      residentId: json['resident_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resident_id': residentId,
      'title': title,
      'description': description,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ComplaintChat {
  final String id;
  final String complaintId;
  final String senderId;
  final String message;
  final DateTime? createdAt;

  const ComplaintChat({
    required this.id,
    required this.complaintId,
    required this.senderId,
    required this.message,
    this.createdAt,
  });

  factory ComplaintChat.fromJson(Map<String, dynamic> json) {
    return ComplaintChat(
      id: json['id'] as String? ?? '',
      complaintId: json['complaint_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'sender_id': senderId,
      'message': message,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
