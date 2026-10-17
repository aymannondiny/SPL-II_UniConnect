import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/data/session_repository.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/model/auth_session.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';

/// Owns the in-memory session, serialized refresh, and login/logout state.
class SessionController extends ChangeNotifier {
  SessionController(this._repository);
  final SessionRepository _repository;

  AuthSession? _session;
  Timer? _refreshTimer;
  bool _disposed = false;
  bool busy = false;
  CurrentAccount? account;
  AuthFailure? failure;

  /// Current short-lived bearer token for authenticated feature repositories.
  /// The token remains in memory and changes when [refresh] rotates the session.
  String? get accessToken => _session?.accessToken;

  Future<void> login(String email, String password) async {
    if (busy || account != null || _disposed) return;
    await _perform(() async {
      final session = await _repository.login(
        email.trim().toLowerCase(),
        password,
      );
      if (_disposed) return;
      _session = session;
      final currentAccount = await _repository.account(session.accessToken);
      if (_disposed) return;
      account = currentAccount;
      _scheduleRefresh();
    }, clearOnFailure: true);
  }

  Future<void> refresh() async {
    if (busy || _session == null || _disposed) return;
    await _perform(() async {
      if (!DateTime.now().isBefore(_session!.expiresAt)) {
        throw const AuthFailure('Your session has ended. Please log in again.');
      }
      final replacement = await _repository.refresh(_session!.refreshToken);
      if (_disposed) return;
      _session = replacement;
      _scheduleRefresh();
    }, clearOnFailure: true);
  }

  Future<void> logout() async {
    if (busy || _session == null || _disposed) return;
    _refreshTimer?.cancel();
    await _perform(() async {
      if (!DateTime.now().isBefore(_session!.accessExpiresAt)) {
        final replacement = await _repository.refresh(_session!.refreshToken);
        if (_disposed) return;
        _session = replacement;
      }
      await _repository.logout(_session!.accessToken);
      _clearSession();
    });
    if (!_disposed && _session != null) _scheduleRefresh();
  }

  void clearFailure() {
    if (failure == null) return;
    failure = null;
    _notify();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final expiry = _session!.accessExpiresAt.isBefore(_session!.expiresAt)
        ? _session!.accessExpiresAt
        : _session!.expiresAt;
    final remaining = expiry.difference(DateTime.now());
    final delay = remaining > const Duration(seconds: 30)
        ? remaining - const Duration(seconds: 30)
        : remaining;
    _refreshTimer = Timer(delay.isNegative ? Duration.zero : delay, refresh);
  }

  Future<void> _perform(
    Future<void> Function() action, {
    bool clearOnFailure = false,
  }) async {
    busy = true;
    failure = null;
    _notify();
    try {
      await action();
    } on AuthFailure catch (error) {
      if (clearOnFailure || error.sessionEnded) _clearSession();
      failure = error;
    } on Object {
      if (clearOnFailure) _clearSession();
      failure = const AuthFailure('Something went wrong. Please try again.');
    } finally {
      busy = false;
      _notify();
    }
  }

  void _clearSession() {
    _refreshTimer?.cancel();
    _session = null;
    account = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _clearSession();
    super.dispose();
  }
}
