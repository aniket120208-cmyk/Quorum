class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isEmailVerified,
    this.isOnboarded,
    this.useCases = const [],
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool isEmailVerified;
  final bool? isOnboarded;
  final List<String> useCases;

  AppUser copyWith({bool? isOnboarded, List<String>? useCases}) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: role,
      isEmailVerified: isEmailVerified,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      useCases: useCases ?? this.useCases,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: '${json['role'] ?? 'member'}',
      isEmailVerified: _readVerified(json),
      isOnboarded: json['isOnboarded'] is bool ? json['isOnboarded'] as bool : null,
      useCases: _readUseCases(json['useCases']),
    );
  }

  static List<String> _readUseCases(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => '$e').toList();
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