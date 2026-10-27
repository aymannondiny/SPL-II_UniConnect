class VerificationFailure implements Exception {
  const VerificationFailure(this.message, {this.invalidCode = false});

  final String message;
  final bool invalidCode;
}
