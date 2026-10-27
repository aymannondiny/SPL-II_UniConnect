import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/app.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/fake_profile_repository.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('validates, logs in and logs out at $size, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = FakeSessionRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: LoginPage(
              repository: repository,
              profileRepository: FakeProfileRepository()
                ..profile = FakeProfileRepository.fixture(),
            ),
          ),
        );
        await tester.ensureVisible(find.text('Log in'));
        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();
        expect(find.text('Enter a valid email address.'), findsOneWidget);
        expect(find.text('Enter your password.'), findsOneWidget);
        expect(repository.loginCalls, 0);
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Member@IUT-DHAKA.EDU',
        );
        await tester.enterText(find.byType(TextFormField).at(1), ' pass word ');
        await tester.ensureVisible(find.byTooltip('Show password'));
        await tester.tap(find.byTooltip('Show password'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Hide password'), findsOneWidget);
        await tester.ensureVisible(find.text('Log in'));
        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();
        expect(find.text('Your student workspace'), findsOneWidget);
        expect(find.textContaining('Test'), findsWidgets);
        expect(repository.password, ' pass word ');
        if (size.width < 900) {
          await tester.tap(find.byTooltip('Account menu'));
          await tester.pumpAndSettle();
        }
        final logout = size.width < 900
            ? find.text('Log out')
            : find.byTooltip('Log out');
        await tester.ensureVisible(logout);
        await tester.tap(logout);
        await tester.pumpAndSettle();
        expect(find.text('Log in to UniConnect'), findsOneWidget);
        expect(repository.logoutCalls, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'submission disables duplicates and failed login supports retry',
    (tester) async {
      final repository = FakeSessionRepository()
        ..pending = Completer<void>()
        ..failure = const AuthFailure('Unable to log in.');
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            repository: repository,
            profileRepository: FakeProfileRepository()
              ..profile = FakeProfileRepository.fixture(),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'member@iut-dhaka.edu',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.ensureVisible(find.text('Log in'));
      await tester.tap(find.text('Log in'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Unable to log in.'), findsOneWidget);
      repository.failure = null;
      await tester.ensureVisible(find.text('Log in'));
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Your student workspace'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('theme persists through signup/login/recovery navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const UniConnectApp());
    // The app starts in the wireframe's dark theme, so switch to light and
    // verify that the preference survives navigation between auth pages.
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Log in to UniConnect'))).brightness,
      Brightness.light,
    );
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Reset your password'))).brightness,
      Brightness.light,
    );
    expect(tester.takeException(), isNull);
  });
}
