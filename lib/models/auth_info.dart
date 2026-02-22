class AuthInfo {
  final String accessToken;
  final DateTime? expiresAt;
  final String name;
  final String? email;

  const AuthInfo({
    required this.accessToken,
    required this.expiresAt,
    required this.name,
    required this.email,
  });
}

