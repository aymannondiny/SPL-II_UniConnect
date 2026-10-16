/// The SMTP contract puts the token in the fragment, never the query string.
class VerificationLink {
  const VerificationLink(this.token);

  final String? token;

  static VerificationLink? fromUri(Uri uri) {
    if (uri.path != '/verify-email') return null;
    try {
      final values = Uri.splitQueryString(uri.fragment);
      return VerificationLink(values['token']);
    } on FormatException {
      return const VerificationLink(null);
    }
  }

  static bool isValidToken(String? token) {
    return token != null && RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token);
  }
}
