/// User model representing a customer in the cooperative gig platform.
class User {
  final String id;
  final String phone;
  final String name;
  final String role;
  final String languagePref;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.languagePref = 'en',
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String? ?? json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      languagePref: json['language_pref'] as String? ?? 'en',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'role': role,
      'language_pref': languagePref,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
