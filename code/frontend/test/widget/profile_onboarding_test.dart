import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';
import 'package:uniconnect/features/authentication/view/widgets/login_form.dart';

import '../../tool/support/fake_profile_repository.dart';
import '../../tool/support/fake_session_repository.dart';

Future<void> _field(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

Future<void> _select(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(DropdownButtonFormField<int>, label);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final alumni in [false, true]) {
    testWidgets(
      'onboarding validates and retries partial privacy save; alumni=$alumni',
      (tester) async {
        final profile = FakeProfileRepository()..failPrivacy = true;
        final auth = FakeSessionRepository()
          ..role = alumni ? 'ALUMNI' : 'STUDENT';
        await tester.pumpWidget(
          MaterialApp(
            home: LoginPage(repository: auth, profileRepository: profile),
          ),
        );
        await _field(tester, 'University email', 'member@iut-dhaka.edu');
        await _field(tester, 'Password', 'password');
        await tester.ensureVisible(find.text('Log in'));
        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();
        expect(find.text('Make yourself at home.'), findsOneWidget);
        await tester.ensureVisible(find.text('Save and continue'));
        await tester.tap(find.text('Save and continue'));
        await tester.pumpAndSettle();
        expect(profile.saved, isNull);
        await _field(tester, 'Full name', 'Campus Member');
        await _field(tester, 'Skills', 'Flutter, flutter, SQL');
        await _select(tester, 'Department', 'Computer Science and Engineering');
        await _select(tester, 'Programme', 'Software Engineering');
        await _select(tester, 'Degree', 'Bachelor');
        if (alumni) {
          await _field(tester, 'Graduation year', '2024');
          await _field(tester, 'LinkedIn URL', 'https://example.com/member');
          await tester.ensureVisible(find.text('Save and continue'));
          await tester.tap(find.text('Save and continue'));
          await tester.pumpAndSettle();
          expect(profile.saved, isNull);
          await _field(
            tester,
            'LinkedIn URL',
            'https://linkedin.com/in/example',
          );
        } else {
          await _field(tester, 'Student number', '230042141');
          await _field(tester, 'Year of study', '5');
          await tester.ensureVisible(find.text('Save and continue'));
          await tester.tap(find.text('Save and continue'));
          await tester.pumpAndSettle();
          expect(profile.saved, isNull);
          await _field(tester, 'Year of study', '3');
        }
        await tester.ensureVisible(find.text('Save and continue'));
        await tester.tap(find.text('Save and continue'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(RegExp(r'^Your (student|alumni) workspace$')),
          findsNothing,
        );
        expect(
          find.textContaining('Retry to finish saving privacy'),
          findsOneWidget,
        );
        expect(profile.saved!['skills'], ['flutter', 'sql']);
        expect(profile.savedRole, alumni ? 'ALUMNI' : 'STUDENT');
        profile.failPrivacy = false;
        await tester.ensureVisible(find.text('Save changes'));
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(RegExp(r'^Your (student|alumni) workspace$')),
          findsOneWidget,
        );
        final greetingPosition = tester
            .getTopLeft(
              find.text(
                alumni
                    ? 'Share your experience. Connect with your community.'
                    : 'Your campus. Your people. Your next possibility.',
              ),
            )
            .dy;
        expect(greetingPosition, greaterThan(0));
        expect(greetingPosition, lessThan(500));
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('session expiry returns the authenticated workspace to login', (
    tester,
  ) async {
    final profile = FakeProfileRepository()
      ..profile = FakeProfileRepository.fixture();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          repository: FakeSessionRepository(),
          profileRepository: profile,
        ),
      ),
    );
    final session = tester.widget<LoginForm>(find.byType(LoginForm)).controller;
    await _field(tester, 'University email', 'member@iut-dhaka.edu');
    await _field(tester, 'Password', 'password');
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(RegExp(r'^Your (student|alumni) workspace$')),
      findsOneWidget,
    );
    session.expire();
    await tester.pumpAndSettle();
    expect(find.text('Log in to UniConnect'), findsOneWidget);
    expect(find.textContaining('Your session has ended'), findsOneWidget);
  });
}
