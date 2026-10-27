import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/data/registration_repository.dart';
import 'package:uniconnect/features/authentication/model/registration.dart';
import 'package:uniconnect/features/authentication/view/sign_up_page.dart';

class FakeRegistrationRepository implements RegistrationRepository {
  RegistrationRequest? request;
  int resendCount = 0;

  @override
  Future<RegistrationResult> register(RegistrationRequest value) async {
    request = value;
    return const RegistrationResult(
      email: 'ayman@iut-dhaka.edu',
      accountStatus: 'PENDING_VERIFICATION',
    );
  }

  @override
  Future<void> resendVerification(String email) async {
    resendCount++;
  }
}

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('validates and completes registration at $size dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = FakeRegistrationRepository();
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: SignUpPage(repository: repository),
          ),
        );
        await tester.ensureVisible(find.text('Create my account'));
        await tester.tap(find.text('Create my account'));
        await tester.pumpAndSettle();
        expect(find.text('Enter your full name.'), findsOneWidget);
        expect(repository.request, isNull);
        await tester.enterText(find.byType(TextFormField).at(0), 'Ayman');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'ayman@iut-dhaka.edu',
        );
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'R7!mQ2#vL9@x',
        );
        await tester.enterText(find.byType(TextFormField).at(3), 'different');
        await tester.ensureVisible(find.text('Create my account'));
        await tester.tap(find.text('Create my account'));
        await tester.pumpAndSettle();
        expect(repository.request, isNull);
        expect(find.text('Passwords must match.'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).at(3),
          'R7!mQ2#vL9@x',
        );
        await tester.ensureVisible(find.text('Alumni'));
        await tester.tap(find.text('Alumni'));
        await tester.ensureVisible(find.text('Create my account'));
        await tester.tap(find.text('Create my account'));
        await tester.pumpAndSettle();
        expect(repository.request!.role, RegistrationRole.alumni);
        expect(find.text('Check your email'), findsOneWidget);
        expect(find.text('Verification code'), findsOneWidget);
        expect(find.text('ayman@iut-dhaka.edu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
