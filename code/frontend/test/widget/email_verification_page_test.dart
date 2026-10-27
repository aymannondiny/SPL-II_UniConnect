import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/data/email_verification_repository.dart';
import 'package:uniconnect/features/authentication/model/verification_failure.dart';
import 'package:uniconnect/features/authentication/view/email_verification_page.dart';

class FakeVerificationRepository implements EmailVerificationRepository {
  int calls = 0;
  String? email;
  String? code;
  String? replacementEmail;
  Completer<void>? pending;
  VerificationFailure? failure;

  @override
  Future<void> verify(String email, String code) async {
    calls++;
    this.email = email;
    this.code = code;
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
    String email = '',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: EmailVerificationPage(email: email, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Verify email'));
    await tester.tap(find.text('Verify email'));
    await tester.pump();
  }

  for (final size in [
    const Size(1440, 1000),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    testWidgets('code entry and login work without overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeVerificationRepository()
        ..pending = Completer<void>();
      await showPage(tester, repository, email: 'member@iut-dhaka.edu');
      expect(repository.calls, 0);
      await tester.enterText(
        find.byKey(const ValueKey('verification-code')),
        '012345',
      );
      await submit(tester);
      expect(find.text('Verifying…'), findsOneWidget);
      expect(repository.calls, 1);
      expect(repository.email, 'member@iut-dhaka.edu');
      expect(repository.code, '012345');
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Log in to UniConnect'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('validates both fields and resends without requiring a code', (
    tester,
  ) async {
    final repository = FakeVerificationRepository();
    await showPage(tester, repository);
    await submit(tester);
    expect(repository.calls, 0);
    expect(
      find.text('Enter the six-digit code from your email.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      ' MEMBER@IUT-DHAKA.EDU ',
    );
    await tester.ensureVisible(find.text('Resend code'));
    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();
    expect(repository.replacementEmail, 'member@iut-dhaka.edu');
    expect(find.textContaining('If your account is eligible'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('invalid code remains editable and can be retried', (
    tester,
  ) async {
    final repository = FakeVerificationRepository()
      ..failure = const VerificationFailure(
        'Code is no longer usable',
        invalidCode: true,
      );
    await showPage(tester, repository, email: 'member@iut-dhaka.edu');
    await tester.enterText(
      find.byKey(const ValueKey('verification-code')),
      '111111',
    );
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Code is no longer usable'), findsOneWidget);
    expect(find.text('Your email has been verified'), findsNothing);
    repository.failure = null;
    await tester.enterText(
      find.byKey(const ValueKey('verification-code')),
      '012345',
    );
    await submit(tester);
    await tester.pumpAndSettle();
    expect(repository.code, '012345');
    expect(find.text('Log in to UniConnect'), findsOneWidget);
  });

  testWidgets('old verification URL opens code entry without API submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/verify-email',
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification code'), findsOneWidget);
    expect(find.textContaining('link is'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose during request does not notify dead view', (
    tester,
  ) async {
    final repository = FakeVerificationRepository()
      ..pending = Completer<void>();
    await showPage(tester, repository, email: 'member@iut-dhaka.edu');
    await tester.enterText(
      find.byKey(const ValueKey('verification-code')),
      '012345',
    );
    await submit(tester);
    await tester.pumpWidget(const SizedBox());
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
