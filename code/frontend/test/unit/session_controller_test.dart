import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  test('deduplicates login and preserves password whitespace', () async {
    final repository = FakeSessionRepository()..pending = Completer<void>();
    final controller = SessionController(repository);
    addTearDown(controller.dispose);
    final pending = controller.login(' Member@IUT-DHAKA.EDU ', ' pass word ');
    await controller.login('other@example.edu', 'other');
    expect(controller.busy, isTrue);
    expect(repository.loginCalls, 1);
    repository.pending!.complete();
    await pending;
    expect(repository.email, 'member@iut-dhaka.edu');
    expect(repository.password, ' pass word ');
    expect(controller.account!.fullName, 'Test Member');
    expect(repository.accountToken, 'access-login');
  });

  test('serializes refresh and logs out with rotated credentials', () async {
    final repository = FakeSessionRepository();
    final controller = SessionController(repository);
    addTearDown(controller.dispose);
    await controller.login('a@b.edu', 'password');
    repository.pending = Completer<void>();
    final pending = controller.refresh();
    final concurrent = controller.refresh();
    expect(repository.refreshCalls, 1);
    repository.pending!.complete();
    await pending;
    await concurrent;
    await controller.logout();
    expect(repository.logoutToken, 'access-rotated');
    expect(controller.account, isNull);
  });

  test('failed refresh clears session; failed logout permits retry', () async {
    final repository = FakeSessionRepository();
    final controller = SessionController(repository);
    addTearDown(controller.dispose);
    await controller.login('a@b.edu', 'password');
    repository.failure = const AuthFailure('Offline');
    await controller.logout();
    expect(controller.account, isNotNull);
    expect(controller.failure!.message, 'Offline');
    await controller.refresh();
    expect(controller.account, isNull);
  });

  test(
    'disposing in-flight login does not retain a session or notify',
    () async {
      final repository = FakeSessionRepository()..pending = Completer<void>();
      final controller = SessionController(repository);
      final pending = controller.login('a@b.edu', 'password');
      controller.dispose();
      repository.pending!.complete();
      await pending;
      expect(controller.account, isNull);
      expect(repository.accountToken, isNull);
    },
  );

  test('revoked session during logout returns to login', () async {
    final repository = FakeSessionRepository();
    final controller = SessionController(repository);
    addTearDown(controller.dispose);
    await controller.login('a@b.edu', 'password');
    repository.failure = const AuthFailure('Session ended', sessionEnded: true);
    await controller.logout();
    expect(controller.account, isNull);
    expect(controller.failure!.message, 'Session ended');
  });

  testWidgets('automatically renews access and clears failed renewal', (
    tester,
  ) async {
    final repository = FakeSessionRepository();
    final controller = SessionController(repository);
    addTearDown(controller.dispose);
    await controller.login('a@b.edu', 'password');
    await tester.pump(const Duration(minutes: 15));
    expect(repository.refreshCalls, 1);
    expect(controller.account, isNotNull);
    repository.failure = const AuthFailure('Your session has ended.');
    await tester.pump(const Duration(minutes: 15));
    expect(repository.refreshCalls, 2);
    expect(controller.account, isNull);
    expect(controller.failure!.message, 'Your session has ended.');
  });
}
