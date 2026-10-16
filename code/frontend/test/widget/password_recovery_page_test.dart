import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';
import 'package:uniconnect/features/authentication/view/forgot_password_page.dart';
import 'package:uniconnect/features/authentication/view/reset_password_page.dart';

class FakeRecoveryRepository implements PasswordRecoveryRepository {
  String? email;
  String? token;
  String? password;
  AuthFailure? failure;
  Completer<void>? pending;

  @override
  Future<void> requestLink(String email) async {
    this.email = email;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> reset(String token, String newPassword) async {
    this.token = token;
    password = newPassword;
    if (failure != null) throw failure!;
  }
}

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('recovery and reset work at $size, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = FakeRecoveryRepository();
        final theme = dark ? AppTheme.dark() : AppTheme.light();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: ForgotPasswordPage(repository: repository),
          ),
        );
        await tester.ensureVisible(find.text('Send reset link'));
        await tester.tap(find.text('Send reset link'));
        await tester.pumpAndSettle();
        expect(repository.email, isNull);
        await tester.enterText(
          find.byType(TextFormField),
          ' Member@IUT-DHAKA.EDU ',
        );
        await tester.ensureVisible(find.text('Send reset link'));
        await tester.tap(find.text('Send reset link'));
        await tester.pumpAndSettle();
        expect(repository.email, 'member@iut-dhaka.edu');
        expect(
          find.textContaining('If this account is eligible'),
          findsOneWidget,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: ResetPasswordPage(
              link: PasswordResetLink('a' * 43),
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).at(0),
          ' new password ',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'mismatch');
        await tester.ensureVisible(find.text('Update password'));
        await tester.tap(find.text('Update password'));
        await tester.pumpAndSettle();
        expect(find.text('Passwords must match.'), findsOneWidget);
        expect(repository.token, isNull);
        await tester.enterText(
          find.byType(TextFormField).at(1),
          ' new password ',
        );
        await tester.ensureVisible(find.text('Update password'));
        await tester.tap(find.text('Update password'));
        await tester.pumpAndSettle();
        expect(repository.token, 'a' * 43);
        expect(repository.password, ' new password ');
        expect(find.text('Password updated'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('missing link never submits and exposes recovery', (
    tester,
  ) async {
    final repository = FakeRecoveryRepository();
    await tester.pumpWidget(
      MaterialApp(home: ResetPasswordPage(repository: repository)),
    );
    expect(find.text('This link is no longer usable'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Request a new reset link'), findsOneWidget);
    expect(repository.token, isNull);
  });

  testWidgets('forgot-password network failure permits retry', (tester) async {
    final repository = FakeRecoveryRepository()
      ..failure = const AuthFailure('Offline');
    await tester.pumpWidget(
      MaterialApp(home: ForgotPasswordPage(repository: repository)),
    );
    await tester.enterText(find.byType(TextFormField), 'member@iut-dhaka.edu');
    await tester.ensureVisible(find.text('Send reset link'));
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsOneWidget);
    repository.failure = null;
    await tester.ensureVisible(find.text('Send reset link'));
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your inbox'), findsOneWidget);
  });
}
