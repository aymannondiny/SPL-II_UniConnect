import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/fake_chat_repository.dart';

void main() {
  late SessionController session;
  late ApiClient client;
  late FakeChatRepository repository;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@iut-dhaka.edu', 'password');
    client = ApiClient();
    repository = FakeChatRepository(client);
  });
  tearDown(() {
    session.dispose();
    client.close();
  });

  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final recipient in [
      const ChatConnection(userId: 2, fullName: 'Nafisa Rahman'),
      const ChatConnection(userId: 5, fullName: 'Community Member 5'),
    ]) {
      testWidgets(
        'selected recipient ${recipient.userId} opens and sends at $size',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark(),
              home: ChatPage(
                sessionController: session,
                repository: repository,
                initialRecipient: recipient,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(recipient.fullName), findsWidgets);
          if (recipient.userId == 2) expect(repository.openedConversation, 81);
          final composer = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.hintText == 'Write a message',
          );
          expect(composer, findsOneWidget);
          await tester.enterText(composer, 'Hello from a connection');
          await tester.pump();
          await tester.tap(find.byTooltip('Send message'));
          await tester.pumpAndSettle();
          expect(repository.sentRecipient, recipient.userId);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('opening Messages starts in the conversation list at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(sessionController: session, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nafisa Rahman'), findsOneWidget);
      expect(repository.openedConversation, isNull);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Write a message',
        ),
        findsNothing,
      );
      await tester.tap(find.text('Nafisa Rahman'));
      await tester.pumpAndSettle();
      expect(repository.openedConversation, 81);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Write a message',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('revoked connection cannot open a draft composer', (
    tester,
  ) async {
    repository.connected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          sessionController: session,
          repository: repository,
          initialRecipient: const ChatConnection(
            userId: 5,
            fullName: 'Community Member 5',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('no longer an accepted connection'),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Write a message',
      ),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an already visited chat responds to another recipient request', (
    tester,
  ) async {
    Widget page(ChatConnection recipient, int request) => MaterialApp(
      home: ChatPage(
        sessionController: session,
        repository: repository,
        initialRecipient: recipient,
        recipientRequest: request,
      ),
    );
    await tester.pumpWidget(
      page(const ChatConnection(userId: 2, fullName: 'Nafisa Rahman'), 1),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      page(const ChatConnection(userId: 5, fullName: 'Community Member 5'), 2),
    );
    await tester.pumpAndSettle();
    expect(find.text('Community Member 5'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
