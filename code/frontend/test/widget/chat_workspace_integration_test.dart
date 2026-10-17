import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/data/chat_socket_contract.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';
import 'package:uniconnect/features/home/view/widgets/feature_card.dart';

import '../../tool/support/fake_profile_repository.dart';
import '../../tool/support/fake_session_repository.dart';

void main() {
  testWidgets('chat deep link without a session opens login', (tester) async {
    await tester.pumpWidget(
      SessionHost(
        repository: FakeSessionRepository(),
        child: MaterialApp(
          initialRoute: AppRoutes.chat,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    testWidgets('chat panel lays out at $size without backend', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = SessionController(FakeSessionRepository());
      addTearDown(session.dispose);
      await session.login('member@iut-dhaka.edu', 'password');
      final client = ApiClient();
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            sessionController: session,
            repository: _UnavailableChatRepository(client),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Messages'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await session.logout();
    });

    testWidgets('Messages opens chat from workspace at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = SessionController(FakeSessionRepository());
      addTearDown(session.dispose);
      await session.login('member@iut-dhaka.edu', 'password');
      final repository = FakeProfileRepository()
        ..profile = FakeProfileRepository.fixture();
      SessionController? chatSession;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        SessionScope(
          controller: session,
          child: MaterialApp(
            navigatorKey: navigator,
            home: AuthenticatedWorkspace(repository: repository),
            onGenerateRoute: (settings) {
              expect(settings.name, AppRoutes.chat);
              return MaterialPageRoute<void>(
                builder: (context) {
                  chatSession = SessionScope.of(context);
                  return const Scaffold(body: Text('Chat destination'));
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Messages').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('Chat destination'), findsOneWidget);
      expect(identical(chatSession, session), isTrue);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      final card = find.byWidgetPredicate(
        (widget) => widget is FeatureCard && widget.feature.title == 'Messages',
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      if (size.width > 1000) {
        expect(
          find.descendant(of: card, matching: find.text('Open')),
          findsOneWidget,
        );
      }
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('Chat destination'), findsOneWidget);
      expect(repository.loads, 1);
      await session.logout();
      await tester.pumpWidget(const SizedBox());
    });
  }
}

class _UnavailableChatRepository extends ChatRepository {
  _UnavailableChatRepository(super.client);

  @override
  Future<ChatSocketConnection> connect(String token) async =>
      throw const ChatFailure('Backend unavailable in this test.');

  @override
  Future<List<ChatConversation>> conversations(String token) async =>
      throw const ChatFailure('Backend unavailable in this test.');
}
