import 'package:uniconnect/features/authentication/data/auth_transport.dart';

abstract interface class PasswordRecoveryRepository {
  Future<void> requestCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> reset(String email, String code, String newPassword);
}

class ApiPasswordRecoveryRepository implements PasswordRecoveryRepository {
  ApiPasswordRecoveryRepository(this._transport);
  final AuthTransport _transport;

  @override
  Future<void> requestCode(String email) async {
    await _transport.post('/api/v1/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    }, 202);
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    await _transport.post('/api/v1/auth/verify-password-reset-code', {
      'email': email.trim().toLowerCase(),
      'code': code,
    }, 204);
  }

  @override
  Future<void> reset(String email, String code, String newPassword) async {
    await _transport.post('/api/v1/auth/reset-password', {
      'email': email.trim().toLowerCase(),
      'code': code,
      'newPassword': newPassword,
    }, 204);
  }
}
