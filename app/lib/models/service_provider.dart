class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final String phone;
  final DateTime? createdAt;

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    this.createdAt,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
