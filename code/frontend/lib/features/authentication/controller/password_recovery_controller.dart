import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController(this._repository);
  final PasswordRecoveryRepository _repository;

  bool busy = false;
  bool completed = false;
  String? requestedEmail;
  bool _disposed = false;
  AuthFailure? failure;

  Future<void> requestCode(String email) {
    requestedEmail = email.trim().toLowerCase();
    return _perform(() => _repository.requestCode(requestedEmail!));
  }

  Future<void> reset(String email, String code, String password) =>
      _perform(() => _repository.reset(email, code, password));

  Future<void> verifyCode(String email, String code) =>
      _perform(() => _repository.verifyCode(email, code));

  Future<void> resendCode(String email) =>
      _perform(() => _repository.requestCode(email), complete: false);

  void clearFailure() {
    if (failure == null) return;
    failure = null;
    _notify();
  }

  Future<void> _perform(
    Future<void> Function() action, {
    bool complete = true,
  }) async {
    if (busy || completed || _disposed) return;
    busy = true;
    failure = null;
    _notify();
    try {
      await action();
      completed = complete;
    } on AuthFailure catch (error) {
      failure = error;
    } on Object {
      failure = const AuthFailure('Something went wrong. Please try again.');
    } finally {
      busy = false;
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
