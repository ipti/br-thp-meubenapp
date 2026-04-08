class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.name,
    required this.username,
    required this.active,
    required this.role,
    required this.socialTechnologies,
    this.email,
    this.phone,
  });

  final int id;
  final String name;
  final String username;
  final bool active;
  final String role;
  final List<String> socialTechnologies;
  final String? email;
  final String? phone;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'active': active,
      'role': role,
      'socialTechnologies': socialTechnologies,
      'email': email,
      'phone': phone,
    };
  }

  static UserProfileModel fromJson(Map<String, dynamic> json) {
    final coordinators = (json['coordinators'] as List?) ?? const [];
    final reapplicators = (json['reapplicators'] as List?) ?? const [];
    final contactsSource = coordinators.isNotEmpty
        ? coordinators
        : reapplicators;
    Map<String, dynamic>? contacts;
    if (contactsSource.isNotEmpty &&
        contactsSource.first is Map<String, dynamic>) {
      contacts = contactsSource.first as Map<String, dynamic>;
    }

    final userSocialTechnology =
        (json['user_social_technology'] as List?) ?? const [];
    final socialTechnologies = userSocialTechnology
        .map((item) {
          if (item is Map<String, dynamic>) {
            final nested = item['usersocialtechnology'];
            if (nested is Map<String, dynamic>) {
              return nested['name']?.toString() ?? '';
            }
          }
          return '';
        })
        .where((name) => name.isNotEmpty)
        .toList();

    return UserProfileModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      active: json['active'] == true,
      role: json['role']?.toString() ?? '',
      socialTechnologies: socialTechnologies,
      email: contacts?['email']?.toString(),
      phone: contacts?['phone']?.toString(),
    );
  }
}
