import 'package:uniconnect/features/authentication/data/auth_transport.dart';
import 'package:uniconnect/features/authentication/model/auth_session.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';

abstract interface class SessionRepository {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> refresh(String refreshToken);
  Future<CurrentAccount> account(String accessToken);
  Future<void> logout(String accessToken);
}

class ApiSessionRepository implements SessionRepository {
  ApiSessionRepository(this._transport);
  final AuthTransport _transport;

  @override
  Future<AuthSession> login(String email, String password) async {
    final response = await _transport.post('/api/v1/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    }, 200);
    return _transport.decode(response, AuthSession.fromJson);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _transport.post('/api/v1/auth/refresh', {
      'refreshToken': refreshToken,
    }, 200);
    return _transport.decode(response, AuthSession.fromJson);
  }

  @override
  Future<CurrentAccount> account(String accessToken) async {
    final response = await _transport.get('/api/v1/auth/me', accessToken);
    return _transport.decode(response, CurrentAccount.fromJson);
  }

  @override
  Future<void> logout(String accessToken) async {
    await _transport.post(
      '/api/v1/auth/logout',
      null,
      204,
      accessToken: accessToken,
    );
  }
}
