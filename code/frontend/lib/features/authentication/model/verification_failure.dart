class VerificationFailure implements Exception {
  const VerificationFailure(this.message, {this.invalidLink = false});

  final String message;
  final bool invalidLink;
}
