class Notice {
  final String id;
  final String title;
  final String description;
  final String? createdBy;
  final DateTime? createdAt;

  const Notice({
    required this.id,
    required this.title,
    required this.description,
    this.createdBy,
    this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
