import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController(this._repository);
  final PasswordRecoveryRepository _repository;

  bool busy = false;
  bool completed = false;
  bool _disposed = false;
  AuthFailure? failure;

  Future<void> requestLink(String email) =>
      _perform(() => _repository.requestLink(email.trim().toLowerCase()));

  Future<void> reset(String token, String password) =>
      _perform(() => _repository.reset(token, password));

  void clearFailure() {
    if (failure == null) return;
    failure = null;
    _notify();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (busy || completed || _disposed) return;
    busy = true;
    failure = null;
    _notify();
    try {
      await action();
      completed = true;
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
