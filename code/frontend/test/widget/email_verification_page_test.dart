import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/data/email_verification_repository.dart';
import 'package:uniconnect/features/authentication/model/verification_failure.dart';
import 'package:uniconnect/features/authentication/view/email_verification_page.dart';

class FakeVerificationRepository implements EmailVerificationRepository {
  int calls = 0;
  String? replacementEmail;
  Completer<void>? pending;
  VerificationFailure? failure;

  @override
  Future<void> verify(String token) async {
    calls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> resend(String email) async {
    replacementEmail = email;
  }
}

void main() {
  Future<void> showPage(
    WidgetTester tester,
    FakeVerificationRepository repository, {
    String? token,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: EmailVerificationPage(token: token, repository: repository),
      ),
    );
  }

  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    testWidgets('verifies and displays themed success at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeVerificationRepository()
        ..pending = Completer<void>();
      await showPage(tester, repository, token: 'a' * 43);
      expect(find.text('Verifying your email'), findsOneWidget);
      expect(find.text('Your email has been verified'), findsNothing);
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Your email has been verified'), findsOneWidget);
      expect(repository.calls, 1);
      await tester.ensureVisible(find.text('Click to log in'));
      await tester.tap(find.text('Click to log in'));
      await tester.pumpAndSettle();
      expect(find.text('Login screen coming next'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Switch to dark theme'));
      await tester.tap(find.byTooltip('Switch to dark theme'));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Your email has been verified'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(repository.calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'missing token skips API and permits validated replacement request',
    (tester) async {
      final repository = FakeVerificationRepository();
      await showPage(tester, repository);
      await tester.pumpAndSettle();
      expect(repository.calls, 0);
      expect(find.text('Your email has been verified'), findsNothing);
      await tester.ensureVisible(find.text('Send a new link'));
      await tester.tap(find.text('Send a new link'));
      await tester.pumpAndSettle();
      expect(repository.replacementEmail, isNull);
      await tester.enterText(
        find.byType(TextFormField),
        'member@iut-dhaka.edu',
      );
      await tester.ensureVisible(find.text('Send a new link'));
      await tester.tap(find.text('Send a new link'));
      await tester.pumpAndSettle();
      expect(repository.replacementEmail, 'member@iut-dhaka.edu');
      expect(
        find.textContaining('If your account is awaiting verification'),
        findsOneWidget,
      );
    },
  );

  testWidgets('expired token shows recovery; network failure supports retry', (
    tester,
  ) async {
    final repository = FakeVerificationRepository()
      ..failure = const VerificationFailure('Link expired', invalidLink: true);
    await showPage(tester, repository, token: 'a' * 43);
    await tester.pumpAndSettle();
    expect(find.text('Link expired'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    repository.failure = const VerificationFailure('Cannot reach UniConnect');
    await showPage(tester, repository, token: 'a' * 43);
    await tester.pumpAndSettle();
    expect(find.text('Your email has been verified'), findsNothing);
    repository.failure = null;
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Your email has been verified'), findsOneWidget);
  });

  testWidgets('disposing during verification does not notify a dead view', (
    tester,
  ) async {
    final repository = FakeVerificationRepository()
      ..pending = Completer<void>();
    await showPage(tester, repository, token: 'a' * 43);
    await tester.pumpWidget(const SizedBox());
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
