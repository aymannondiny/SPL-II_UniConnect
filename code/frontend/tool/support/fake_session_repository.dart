import 'dart:async';

import 'package:uniconnect/features/authentication/data/session_repository.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/model/auth_session.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';

class FakeSessionRepository implements SessionRepository {
  String role = 'STUDENT';
  String? email;
  String? password;
  int loginCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;
  AuthFailure? failure;
  Completer<void>? pending;
  String? accountToken;
  String? logoutToken;

  AuthSession session(String suffix) => AuthSession(
    accessToken: 'access-$suffix',
    refreshToken: 'refresh-$suffix',
    accessExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );

  @override
  Future<AuthSession> login(String email, String password) async {
    loginCalls++;
    this.email = email;
    this.password = password;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    return session('login');
  }

  @override
  Future<CurrentAccount> account(String accessToken) async {
    accountToken = accessToken;
    return CurrentAccount(
      userId: 1,
      fullName: 'Test Member',
      email: 'member@iut-dhaka.edu',
      platformRole: role,
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    refreshCalls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    return session('rotated');
  }

  @override
  Future<void> logout(String accessToken) async {
    logoutCalls++;
    logoutToken = accessToken;
    if (failure != null) throw failure!;
  }
}
