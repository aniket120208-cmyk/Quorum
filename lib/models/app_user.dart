class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isEmailVerified,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool isEmailVerified;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: '${json['role'] ?? 'member'}',
      isEmailVerified: _readVerified(json),
    );
  }

  static bool _readVerified(Map<String, dynamic> json) {
    for (final key in const [
      'isEmailVerified',
      'emailVerified',
      'is_email_verified',
      'email_verified',
      'isVerified',
      'verified',
    ]) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
    }
    final at = json['emailVerifiedAt'] ?? json['email_verified_at'];
    return at != null;
  }
}