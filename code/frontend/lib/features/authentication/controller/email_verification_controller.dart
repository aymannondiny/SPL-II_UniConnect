import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/data/email_verification_repository.dart';
import 'package:uniconnect/features/authentication/model/verification_failure.dart';

/// Owns verification requests without creating or changing a login session.
class EmailVerificationController extends ChangeNotifier {
  EmailVerificationController(this._repository);

  final EmailVerificationRepository _repository;
  bool verifying = false;
  bool resending = false;
  bool verified = false;
  bool _disposed = false;
  String? error;
  String? resendNotice;
  String? resendError;

  bool get busy => verifying || resending;

  Future<void> verify(String email, String code) async {
    if (busy || verified) return;
    verifying = true;
    error = null;
    resendNotice = null;
    resendError = null;
    _notify();
    try {
      await _repository.verify(email.trim().toLowerCase(), code);
      verified = true;
    } on VerificationFailure catch (failure) {
      error = failure.message;
    } on Object {
      error = 'Something went wrong. Please try again.';
    } finally {
      verifying = false;
      _notify();
    }
  }

  Future<void> resend(String email) async {
    if (busy || verified) return;
    resending = true;
    error = null;
    resendError = null;
    resendNotice = null;
    _notify();
    try {
      await _repository.resend(email.trim().toLowerCase());
      resendNotice =
          'If your account is eligible, a verification code may '
          'arrive shortly. Check your spam folder. Requests within 60 seconds '
          'or after the hourly limit may not send another code.';
    } on VerificationFailure catch (failure) {
      resendError = failure.message;
    } on Object {
      resendError = 'Could not request a new code. Please try again.';
    } finally {
      resending = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
