class AuthFailure implements Exception {
  const AuthFailure(
    this.message, {
    this.fieldErrors = const {},
    this.sessionEnded = false,
  });

  final String message;
  final Map<String, String> fieldErrors;
  final bool sessionEnded;
}
