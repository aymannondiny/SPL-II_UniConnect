import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/view/forgot_password_page.dart';
import 'package:uniconnect/features/authentication/view/reset_password_page.dart';
import 'package:uniconnect/features/authentication/view/verify_password_reset_page.dart';

class FakeRecoveryRepository implements PasswordRecoveryRepository {
  String? email;
  String? verifiedCode;
  String? resetCode;
  String? password;
  AuthFailure? failure;
  int requests = 0;

  @override
  Future<void> requestCode(String email) async {
    if (failure != null) throw failure!;
    this.email = email;
    requests++;
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    if (failure != null) throw failure!;
    if (code != '012345') throw const AuthFailure('Incorrect code');
    verifiedCode = code;
    this.email = email;
  }

  @override
  Future<void> reset(String email, String code, String newPassword) async {
    if (failure != null) throw failure!;
    this.email = email;
    resetCode = code;
    password = newPassword;
  }
}

Future<void> press(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> enterCode(WidgetTester tester, String code) async {
  await tester.enterText(
    find.byKey(const ValueKey('reset-code-digit-0')),
    code,
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('three recovery pages at $size dark=$dark', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = FakeRecoveryRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: ForgotPasswordPage(repository: repository),
          ),
        );
        await press(tester, 'Send verification code');
        expect(repository.email, isNull);
        await tester.enterText(
          find.byType(TextFormField),
          ' Member@IUT-DHAKA.EDU ',
        );
        await press(tester, 'Send verification code');
        expect(repository.email, 'member@iut-dhaka.edu');
        expect(find.text('Enter verification code'), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(6));
        expect(find.text('Choose a new password'), findsNothing);
        await enterCode(tester, '111111');
        await press(tester, 'Verify code');
        expect(find.text('Incorrect code'), findsOneWidget);
        expect(find.text('Choose a new password'), findsNothing);
        await enterCode(tester, '012345');
        await press(tester, 'Verify code');
        expect(repository.verifiedCode, '012345');
        expect(find.text('Choose a new password'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        await tester.enterText(
          find.byType(TextFormField).at(0),
          ' reef violet lantern otter ',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'mismatch');
        await press(tester, 'Update password');
        expect(repository.password, isNull);
        expect(find.text('Passwords must match.'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).at(1),
          ' reef violet lantern otter ',
        );
        await press(tester, 'Update password');
        expect(repository.password, ' reef violet lantern otter ');
        expect(repository.resetCode, '012345');
        expect(find.text('Password updated'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'partial code does not call verification and resend stays on page two',
    (tester) async {
      final repository = FakeRecoveryRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: VerifyPasswordResetPage(
            email: 'member@iut-dhaka.edu',
            repository: repository,
          ),
        ),
      );
      await enterCode(tester, '123');
      await press(tester, 'Verify code');
      expect(repository.verifiedCode, isNull);
      expect(
        find.text('Enter the six-digit code from your email.'),
        findsOneWidget,
      );
      await press(tester, 'Resend code');
      expect(repository.requests, 1);
      expect(find.text('Enter verification code'), findsOneWidget);
      await enterCode(tester, '012345');
      await press(tester, 'Verify code');
      expect(find.text('Choose a new password'), findsOneWidget);
    },
  );

  testWidgets('request failure can retry and then advances automatically', (
    tester,
  ) async {
    final repository = FakeRecoveryRepository()
      ..failure = const AuthFailure('Offline');
    await tester.pumpWidget(
      MaterialApp(home: ForgotPasswordPage(repository: repository)),
    );
    await tester.enterText(find.byType(TextFormField), 'member@iut-dhaka.edu');
    await press(tester, 'Send verification code');
    expect(find.text('Offline'), findsOneWidget);
    repository.failure = null;
    await press(tester, 'Send verification code');
    expect(find.text('Enter verification code'), findsOneWidget);
  });

  testWidgets('reset deep link without verified code returns to email entry', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ResetPasswordPage()));
    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('Choose a new password'), findsNothing);
  });
}
