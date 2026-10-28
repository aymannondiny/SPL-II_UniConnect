import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/view/gateway/post_login_gateway_page.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';

import '../../tool/support/fake_profile_repository.dart';
import '../../tool/support/fake_session_repository.dart';

void main() {
  test('gateway playback is exactly 2.5x the approved reference', () {
    expect(
      PostLoginGatewayPage.originalDuration,
      const Duration(milliseconds: 18500),
    );
    expect(PostLoginGatewayPage.playbackSpeed, 2.5);
    expect(
      PostLoginGatewayPage.constructionDuration,
      const Duration(milliseconds: 7400),
    );
    expect(
      PostLoginGatewayPage.completedFrameHold,
      const Duration(milliseconds: 550),
    );
    expect(
      PostLoginGatewayPage.transitionDuration,
      const Duration(milliseconds: 7950),
    );
  });

  for (final mode in AppearanceMode.values) {
    testWidgets('uses the approved ${mode.name} background', (tester) async {
      final appearance = AppearanceController(store: _MemoryAppearanceStore())
        ..value = mode;
      addTearDown(appearance.dispose);
      var completed = 0;
      await tester.pumpWidget(
        ThemePreference(
          controller: appearance,
          child: MaterialApp(
            home: PostLoginGatewayPage(onComplete: () => completed++),
          ),
        ),
      );
      expect(
        find.byKey(Key('post-login-gateway-background-${mode.name}')),
        findsOneWidget,
      );
      final background = tester.widget<Image>(find.byType(Image));
      expect(
        (background.image as AssetImage).assetName,
        PostLoginGatewayPage.backgroundAsset(mode),
      );
      expect(background.fit, BoxFit.cover);
      await tester.tap(find.byKey(const Key('post-login-gateway-skip')));
      await tester.pump();
      expect(completed, 1);
    });
  }

  testWidgets('skip completes once and cancels the delayed redirect', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: PostLoginGatewayPage(onComplete: () => completed++)),
    );
    await tester.tap(find.byKey(const Key('post-login-gateway-skip')));
    await tester.tap(find.byKey(const Key('post-login-gateway-skip')));
    await tester.pump(PostLoginGatewayPage.constructionDuration);
    await tester.pump(PostLoginGatewayPage.completedFrameHold);
    expect(completed, 1);
  });

  testWidgets('animation completes automatically after its final frame', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: PostLoginGatewayPage(onComplete: () => completed++)),
    );
    expect(completed, 0);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(completed, 1);
  });

  testWidgets('reduced motion shows the completed frame only briefly', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: PostLoginGatewayPage(onComplete: () => completed++),
        ),
      ),
    );
    expect(find.byKey(const Key('post-login-gateway')), findsOneWidget);
    expect(completed, 0);
    await tester.pump(PostLoginGatewayPage.reducedMotionHold);
    expect(completed, 1);
  });

  for (final size in const [Size(320, 640), Size(800, 600), Size(1440, 900)]) {
    testWidgets('foreground scales without overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: PostLoginGatewayPage(onComplete: () {})),
      );
      expect(
        tester.getSize(find.byKey(const Key('post-login-gateway-foreground'))),
        Size(size.width - 24, size.height - 24),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('post-login-gateway-skip')));
      await tester.pump();
    });
  }

  testWidgets('failed login never enters the gateway', (tester) async {
    final repository = FakeSessionRepository()
      ..failure = const AuthFailure('Unable to log in.');
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          repository: repository,
          profileRepository: FakeProfileRepository(),
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
    await tester.pumpAndSettle();
    expect(find.text('Unable to log in.'), findsOneWidget);
    expect(find.byKey(const Key('post-login-gateway')), findsNothing);
  });

  for (final role in const ['STUDENT', 'ALUMNI', 'SYSTEM_ADMIN']) {
    testWidgets('successful $role login gates the existing role workspace', (
      tester,
    ) async {
      final repository = FakeSessionRepository()..role = role;
      final session = SessionController(repository);
      await tester.pumpWidget(
        SessionScope(
          controller: session,
          child: MaterialApp(
            home: LoginPage(
              profileRepository: FakeProfileRepository()
                ..profile = FakeProfileRepository.fixture(
                  role: role == 'SYSTEM_ADMIN' ? 'STUDENT' : role,
                ),
            ),
          ),
        ),
      );
      await session.login('member@iut-dhaka.edu', 'password');
      await tester.pump();
      expect(find.byKey(const Key('post-login-gateway')), findsOneWidget);
      expect(find.byType(AuthenticatedWorkspace), findsNothing);
      await tester.tap(find.byKey(const Key('post-login-gateway-skip')));
      await tester.pump();
      expect(find.byType(AuthenticatedWorkspace), findsOneWidget);
      expect(session.account?.platformRole, role);

      final navigation =
          Navigator.of(tester.element(find.byType(AuthenticatedWorkspace)))
              .push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Temporary route')),
                ),
              );
      await tester.pumpAndSettle();
      expect(find.text('Temporary route'), findsOneWidget);
      Navigator.of(tester.element(find.text('Temporary route'))).pop();
      await tester.pumpAndSettle();
      await navigation;
      expect(find.byKey(const Key('post-login-gateway')), findsNothing);

      session.updateName('Updated Member');
      await tester.pump();
      expect(find.byKey(const Key('post-login-gateway')), findsNothing);
      expect(find.byType(AuthenticatedWorkspace), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    });
  }

  testWidgets('session expiry removes an in-progress gateway', (tester) async {
    final session = SessionController(FakeSessionRepository());
    await tester.pumpWidget(
      SessionScope(
        controller: session,
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await session.login('member@iut-dhaka.edu', 'password');
    await tester.pump();
    expect(find.byKey(const Key('post-login-gateway')), findsOneWidget);
    session.expire();
    await tester.pump();
    expect(find.byKey(const Key('post-login-gateway')), findsNothing);
    expect(find.text('Log in to UniConnect'), findsOneWidget);
    expect(
      find.text('Your session has ended. Please log in again.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
}

class _MemoryAppearanceStore implements AppearanceStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}
