import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/data/registration_repository.dart';
import 'package:uniconnect/features/authentication/model/registration.dart';

class RegistrationController extends ChangeNotifier {
  RegistrationController(this._repository);
  final RegistrationRepository _repository;

  bool busy = false;
  RegistrationResult? result;
  RegistrationFailure? failure;
  String? notice;
  bool _disposed = false;

  Future<void> submit(RegistrationRequest request) async {
    if (busy || result != null) return;
    await _perform(() async {
      result = await _repository.register(request);
    });
  }

  Future<void> resend() async {
    if (busy || result == null) return;
    await _perform(() async {
      await _repository.resendVerification(result!.email);
      notice = 'If your account is eligible, a new link will arrive shortly. Check your spam folder too.';
    });
  }

  void clearFieldError(String field) {
    if (failure == null) return;
    final errors = Map<String, String>.of(failure!.fieldErrors)..remove(field);
    failure = errors.isEmpty
        ? null
        : RegistrationFailure(failure!.message, fieldErrors: errors);
    _notify();
  }

  Future<void> _perform(Future<void> Function() action) async {
    busy = true;
    failure = null;
    notice = null;
    _notify();
    try {
      await action();
    } on RegistrationFailure catch (error) {
      failure = error;
    } on Object {
      failure = const RegistrationFailure(
        'Something went wrong. Please try again.',
      );
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
