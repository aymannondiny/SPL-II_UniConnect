import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';
import 'package:uniconnect/features/profile/controller/profile_controller.dart';
import 'package:uniconnect/features/profile/view/profile_setup_page.dart';

import '../../tool/support/fake_profile_repository.dart';
import '../../tool/support/fake_session_repository.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      for (final role in ['STUDENT', 'ALUMNI']) {
        testWidgets('profile edit saves $role at $size dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = FakeProfileRepository()
            ..profile = FakeProfileRepository.fixture(role: role);
          final controller = ProfileController(repository);
          addTearDown(controller.dispose);
          await controller.load();
          var saved = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (_, _) => ProfileSetupPage(
                        account: CurrentAccount(
                          userId: 1,
                          fullName: 'Test Member',
                          email: 'member@iut-dhaka.edu',
                          platformRole: role,
                        ),
                        controller: controller,
                        onSaved: () => saved = true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final name = find.widgetWithText(TextFormField, 'Full name');
          await tester.ensureVisible(name);
          await tester.enterText(name, 'Changed Member');
          await tester.ensureVisible(find.text('Save changes'));
          await tester.tap(find.text('Save changes'));
          await tester.pumpAndSettle();
          expect(saved, isTrue);
          expect(repository.saved!['fullName'], 'Changed Member');
          expect(repository.savedRole, role);
          expect(repository.saved!.containsKey('email'), isFalse);
          expect(repository.detailsVisibility, 'CONNECTIONS_ONLY');
          expect(find.text('Only me'), findsNothing);
        });
      }
      testWidgets(
        'home/profile navigation retains app session at $size dark=$dark',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final session = SessionController(FakeSessionRepository());
          addTearDown(session.dispose);
          await session.login('member@iut-dhaka.edu', 'password');
          final repository = FakeProfileRepository()
            ..profile = FakeProfileRepository.fixture();
          await tester.pumpWidget(
            SessionScope(
              controller: session,
              child: MaterialApp(
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                home: AuthenticatedWorkspace(repository: repository),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Everything in UniConnect'), findsOneWidget);
          await tester.ensureVisible(find.text('Manage my profile'));
          await tester.tap(find.text('Manage my profile'));
          await tester.pumpAndSettle();
          expect(find.text('About you'), findsOneWidget);
          await tester.ensureVisible(find.text('Back to home'));
          await tester.tap(find.text('Back to home'));
          await tester.pumpAndSettle();
          expect(find.text('Everything in UniConnect'), findsOneWidget);
          expect(repository.loads, 1);
          expect(await session.accessToken(), 'access-login');
          await session.logout();
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets('empty catalog blocks setup and offers reload', (tester) async {
    final repository = FakeProfileRepository()..emptyCatalog = true;
    final controller = ProfileController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileSetupPage(
              account: const CurrentAccount(
                userId: 1,
                fullName: 'Test',
                email: 'member@iut-dhaka.edu',
              ),
              controller: controller,
              onSaved: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      find.textContaining('Academic options are not available'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save and continue'),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Reload academic options'), findsOneWidget);
  });
}
