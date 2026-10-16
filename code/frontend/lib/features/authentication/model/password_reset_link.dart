class PasswordResetLink {
  const PasswordResetLink(this.token);
  final String? token;

  static PasswordResetLink? fromUri(Uri uri) {
    if (uri.path != '/reset-password') return null;
    try {
      return PasswordResetLink(Uri.splitQueryString(uri.fragment)['token']);
    } on FormatException {
      return const PasswordResetLink(null);
    }
  }

  bool get isValid =>
      token != null && RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token!);
}
