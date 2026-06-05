class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }
}
