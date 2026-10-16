import 'package:uniconnect/features/authentication/data/auth_transport.dart';

abstract interface class PasswordRecoveryRepository {
  Future<void> requestLink(String email);
  Future<void> reset(String token, String newPassword);
}

class ApiPasswordRecoveryRepository implements PasswordRecoveryRepository {
  ApiPasswordRecoveryRepository(this._transport);
  final AuthTransport _transport;

  @override
  Future<void> requestLink(String email) async {
    await _transport.post('/api/v1/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    }, 202);
  }

  @override
  Future<void> reset(String token, String newPassword) async {
    await _transport.post('/api/v1/auth/reset-password', {
      'token': token,
      'newPassword': newPassword,
    }, 204);
  }
}
