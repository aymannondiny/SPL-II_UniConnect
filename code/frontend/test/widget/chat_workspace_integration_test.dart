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
      final client = ApiClient();
      addTearDown(client.close);
      await tester.pumpWidget(
        SessionScope(
          controller: session,
          child: MaterialApp(
            home: AuthenticatedWorkspace(
              repository: repository,
              chatRepository: _UnavailableChatRepository(client),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Messages').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);
      await tester.tap(find.text('Home').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('Your student workspace'), findsOneWidget);
      await tester.tap(find.text('Messages').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);
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
