/// Credentials are held only in memory and are never included in diagnostics.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime expiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'] as String;
    final refresh = json['refreshToken'] as String;
    final accessExpiry = DateTime.parse(json['accessExpiresAt'] as String);
    final expiry = DateTime.parse(json['expiresAt'] as String);
    if (access.isEmpty ||
        refresh.isEmpty ||
        json['tokenType'] != 'Bearer' ||
        !accessExpiry.isAfter(DateTime.now()) ||
        !expiry.isAfter(DateTime.now())) {
      throw const FormatException('Invalid session response');
    }
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: accessExpiry,
      expiresAt: expiry,
    );
  }
}
