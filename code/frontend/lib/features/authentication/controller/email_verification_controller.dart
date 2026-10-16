import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/data/email_verification_repository.dart';
import 'package:uniconnect/features/authentication/model/verification_failure.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';

enum EmailVerificationStatus { verifying, verified, invalidLink, failed }

class EmailVerificationController extends ChangeNotifier {
  EmailVerificationController(this._repository, this._token);

  final EmailVerificationRepository _repository;
  final String? _token;
  EmailVerificationStatus status = EmailVerificationStatus.verifying;
  String? error;
  String? resendNotice;
  String? resendError;
  bool resending = false;
  bool _verifying = false;
  bool _disposed = false;

  Future<void> verify() async {
    if (_verifying || status == EmailVerificationStatus.verified) return;
    if (!VerificationLink.isValidToken(_token)) {
      status = EmailVerificationStatus.invalidLink;
      error =
          'This verification link is incomplete or invalid. '
          'Open the full link from your email or request a new one.';
      _notify();
      return;
    }
    _verifying = true;
    status = EmailVerificationStatus.verifying;
    error = null;
    _notify();
    try {
      await _repository.verify(_token!);
      status = EmailVerificationStatus.verified;
    } on VerificationFailure catch (failure) {
      status = failure.invalidLink
          ? EmailVerificationStatus.invalidLink
          : EmailVerificationStatus.failed;
      error = failure.message;
    } on Object {
      status = EmailVerificationStatus.failed;
      error = 'Something went wrong. Please try again.';
    } finally {
      _verifying = false;
      _notify();
    }
  }

  Future<void> resend(String email) async {
    if (resending) return;
    resending = true;
    resendError = null;
    resendNotice = null;
    _notify();
    try {
      await _repository.resend(email);
      resendNotice =
          'If your account is awaiting verification, a new link '
          'will arrive shortly. Check your spam folder too.';
    } on VerificationFailure catch (failure) {
      resendError = failure.message;
    } on Object {
      resendError = 'Could not request a new link. Please try again.';
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
