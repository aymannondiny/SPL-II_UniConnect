import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/data/chat_socket_contract.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  testWidgets(
    'renders immediately and reconciles REST and repeated socket echoes once',
    (tester) async {
      final harness = await _pumpChat(tester);
      await _openConversation(tester);
      await tester.enterText(_composer(), 'Optimistic hello');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();

      expect(find.text('Optimistic hello'), findsOneWidget);
      expect(find.text('Sending'), findsOneWidget);
      expect(harness.repository.clientMessageIds, hasLength(1));

      final persisted = harness.repository.message(
        id: 501,
        clientMessageId: harness.repository.clientMessageIds.single,
        content: 'Optimistic hello',
      );
      harness.repository.authoritative = persisted;
      harness.repository.emitChanged();
      harness.repository.emitChanged();
      await tester.pumpAndSettle();

      expect(find.text('Optimistic hello'), findsOneWidget);
      expect(find.text('Sending'), findsNothing);

      harness.repository.pendingSends.removeFirst().complete(persisted);
      await tester.pumpAndSettle();

      expect(find.text('Optimistic hello'), findsOneWidget);
      expect(harness.repository.clientMessageIds, hasLength(1));
      harness.repository.emitChanged();
      await tester.pumpAndSettle();
      expect(find.text('Optimistic hello'), findsOneWidget);
      await harness.dispose(tester);
    },
  );

  testWidgets('failed send retries the same logical message id', (
    tester,
  ) async {
    final harness = await _pumpChat(tester);
    await _openConversation(tester);
    await tester.enterText(_composer(), 'Retry me');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    harness.repository.pendingSends.removeFirst().completeError(
      const ChatFailure('Synthetic timeout'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry me'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    final originalId = harness.repository.clientMessageIds.single;

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(harness.repository.clientMessageIds, [originalId, originalId]);
    expect(find.text('Sending'), findsOneWidget);

    harness.repository.pendingSends.removeFirst().complete(
      harness.repository.message(
        id: 502,
        clientMessageId: originalId,
        content: 'Retry me',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry me'), findsOneWidget);
    expect(find.text('Failed'), findsNothing);
    await harness.dispose(tester);
  });

  testWidgets('rapid consecutive messages remain independently pending', (
    tester,
  ) async {
    final harness = await _pumpChat(tester);
    await _openConversation(tester);

    await tester.enterText(_composer(), 'First');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.enterText(_composer(), 'Second');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Sending'), findsNWidgets(2));
    expect(harness.repository.clientMessageIds, hasLength(2));

    final firstRequest = harness.repository.pendingSends.removeFirst();
    final secondRequest = harness.repository.pendingSends.removeFirst();
    firstRequest.complete(
      harness.repository.message(
        id: 601,
        clientMessageId: harness.repository.clientMessageIds[0],
        content: 'First',
      ),
    );
    secondRequest.complete(
      harness.repository.message(
        id: 602,
        clientMessageId: harness.repository.clientMessageIds[1],
        content: 'Second',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Sending'), findsNothing);
    await harness.dispose(tester);
  });
}

Finder _composer() => find.byWidgetPredicate(
  (widget) =>
      widget is TextField && widget.decoration?.hintText == 'Write a message',
);

Future<void> _openConversation(WidgetTester tester) async {
  await tester.tap(find.text('Nafisa Rahman'));
  await tester.pumpAndSettle();
}

Future<_ChatHarness> _pumpChat(WidgetTester tester) async {
  final session = SessionController(FakeSessionRepository());
  await session.login('member@iut-dhaka.edu', 'password');
  final client = ApiClient();
  final repository = _ControlledChatRepository(client);
  await tester.pumpWidget(
    MaterialApp(
      home: ChatPage(sessionController: session, repository: repository),
    ),
  );
  await tester.pumpAndSettle();
  return _ChatHarness(session, client, repository);
}

class _ChatHarness {
  const _ChatHarness(this.session, this.client, this.repository);

  final SessionController session;
  final ApiClient client;
  final _ControlledChatRepository repository;

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await session.logout();
    await repository.dispose();
    client.close();
    session.dispose();
  }
}

class _ControlledChatRepository extends ChatRepository {
  _ControlledChatRepository(super.client);

  final List<StreamController<String>> sockets = [];
  final List<String> clientMessageIds = [];
  final ListQueue<Completer<ChatMessage>> pendingSends = ListQueue();
  ChatMessage? authoritative;

  @override
  Future<ChatSocketConnection> connect(String token) async {
    final events = StreamController<String>.broadcast();
    sockets.add(events);
    return _ControlledSocket(events.stream);
  }

  @override
  Future<List<ChatConversation>> conversations(String token) async => [
    ChatConversation(
      id: 81,
      otherUserId: 2,
      otherFullName: 'Nafisa Rahman',
      canSend: true,
      unreadCount: 0,
      lastMessageAt: authoritative?.sentAt,
      latestVisibleMessage: authoritative,
    ),
  ];

  @override
  Future<ChatHistory> history(
    String token,
    int conversationId, {
    int? beforeMessageId,
  }) async => ChatHistory(
    conversationId: conversationId,
    canSend: true,
    items: authoritative == null ? [] : [authoritative!],
    hasMore: false,
    nextBeforeMessageId: null,
  );

  @override
  Future<ChatMessage> send(
    String token, {
    required int receiverId,
    required String clientMessageId,
    required String content,
  }) {
    clientMessageIds.add(clientMessageId);
    final pending = Completer<ChatMessage>();
    pendingSends.add(pending);
    return pending.future;
  }

  ChatMessage message({
    required int id,
    required String clientMessageId,
    required String content,
  }) => ChatMessage(
    id: id,
    conversationId: 81,
    senderId: 1,
    clientMessageId: clientMessageId,
    content: content,
    sentAt: DateTime.utc(2026, 10, 28, 1),
    deliveredAt: null,
    readAt: null,
    deletedForEveryoneAt: null,
  );

  void emitChanged() {
    sockets.last.add(jsonEncode({'type': 'CHAT_CHANGED'}));
  }

  Future<void> dispose() async {
    for (final socket in sockets) {
      if (!socket.isClosed) await socket.close();
    }
  }
}

class _ControlledSocket implements ChatSocketConnection {
  const _ControlledSocket(this.messages);

  @override
  final Stream<String> messages;

  @override
  void send(String message) {}

  @override
  Future<void> close() async {}
}
