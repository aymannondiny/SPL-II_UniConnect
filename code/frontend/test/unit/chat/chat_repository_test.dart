import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';

void main() {
  group('ChatRepository', () {
    test(
      'loads conversations with bearer auth and maps preview/unread data',
      () async {
        final requests = <http.Request>[];
        final client = _repositoryClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 81,
                  'otherUserId': 17,
                  'otherFullName': 'Nafisa Rahman',
                  'canSend': true,
                  'unreadCount': 2,
                  'lastMessageAt': '2026-10-17T08:20:00',
                  'latestVisibleMessage': _messageJson(
                    id: 301,
                    senderId: 17,
                    content: 'See you there',
                    deliveredAt: '2026-10-17T08:20:00',
                  ),
                },
              ],
            }),
            200,
          );
        });
        addTearDown(client.close);

        final conversations = await ChatRepository(client).conversations('abc');

        expect(requests.single.url.path, '/api/v1/chat/conversations');
        expect(requests.single.url.queryParameters, {
          'page': '0',
          'size': '50',
        });
        expect(requests.single.headers['authorization'], 'Bearer abc');
        expect(conversations, hasLength(1));
        expect(conversations.single.otherFullName, 'Nafisa Rahman');
        expect(conversations.single.unreadCount, 2);
        expect(
          conversations.single.latestVisibleMessage?.content,
          'See you there',
        );
        expect(
          conversations.single.latestVisibleMessage?.deliveredAt,
          DateTime.parse('2026-10-17T08:20:00'),
        );
      },
    );

    test('loads latest and older history using the backend cursor', () async {
      final requests = <http.Request>[];
      final client = _repositoryClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'conversationId': 81,
            'canSend': false,
            'items': [_messageJson(id: 300, senderId: 17, content: 'Older')],
            'hasMore': true,
            'nextBeforeMessageId': 300,
          }),
          200,
        );
      });
      addTearDown(client.close);
      final repository = ChatRepository(client);

      final latest = await repository.history('abc', 81);
      final older = await repository.history(
        'abc',
        81,
        beforeMessageId: latest.nextBeforeMessageId,
      );

      expect(requests[0].url.queryParameters, {'size': '30'});
      expect(requests[1].url.queryParameters, {
        'size': '30',
        'beforeMessageId': '300',
      });
      expect(
        requests.every(
          (request) => request.headers['authorization'] == 'Bearer abc',
        ),
        isTrue,
      );
      expect(latest.conversationId, 81);
      expect(latest.canSend, isFalse);
      expect(latest.items.single.id, 300);
      expect(older.hasMore, isTrue);
    });

    test('loads accepted connections using the documented filter', () async {
      late http.Request request;
      final client = _repositoryClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({
            'items': [
              {'otherUserId': 17, 'fullName': 'Nafisa Rahman'},
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);

      final connections = await ChatRepository(
        client,
      ).acceptedConnections('abc');

      expect(request.url.path, '/api/v1/connections');
      expect(request.url.queryParameters, {
        'status': 'ACCEPTED',
        'direction': 'ALL',
        'sort': 'NAME',
        'size': '50',
        'page': '0',
      });
      expect(connections.single.userId, 17);
      expect(connections.single.fullName, 'Nafisa Rahman');
    });

    test('sends the idempotency key and acknowledges delivery', () async {
      final requests = <http.Request>[];
      final client = _repositoryClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode(
              _messageJson(
                id: 302,
                senderId: 12,
                content: 'Hello',
                clientMessageId: 'client-uuid',
              ),
            ),
            200,
          );
        }
        return http.Response(
          jsonEncode(
            _messageJson(
              id: 301,
              senderId: 12,
              content: 'Hi',
              deliveredAt: '2026-10-17T08:20:00',
            ),
          ),
          200,
        );
      });
      addTearDown(client.close);
      final repository = ChatRepository(client);

      final sent = await repository.send(
        'abc',
        receiverId: 17,
        clientMessageId: 'client-uuid',
        content: 'Hello',
      );
      final delivered = await repository.acknowledgeDelivered('abc', 301);

      expect(requests[0].method, 'POST');
      expect(requests[0].url.path, '/api/v1/chat/messages');
      expect(requests[0].headers['authorization'], 'Bearer abc');
      expect(jsonDecode(requests[0].body), {
        'receiverId': 17,
        'clientMessageId': 'client-uuid',
        'content': 'Hello',
      });
      expect(sent.clientMessageId, 'client-uuid');
      expect(requests[1].method, 'PATCH');
      expect(requests[1].url.path, '/api/v1/chat/messages/301/delivered');
      expect(requests[1].headers['authorization'], 'Bearer abc');
      expect(delivered.deliveredAt, DateTime.parse('2026-10-17T08:20:00'));
    });

    test(
      'deletes for self or everyone and accepts only no-content success',
      () async {
        final requests = <http.Request>[];
        final client = _repositoryClient((request) async {
          requests.add(request);
          return http.Response('', 204);
        });
        addTearDown(client.close);
        final repository = ChatRepository(client);

        await repository.deleteMessage('abc', 301, forEveryone: false);
        await repository.deleteMessage('abc', 302, forEveryone: true);

        expect(requests.map((request) => request.method), ['DELETE', 'DELETE']);
        expect(requests.map((request) => request.url.path), [
          '/api/v1/chat/messages/301/self',
          '/api/v1/chat/messages/302/everyone',
        ]);
        expect(
          requests.every(
            (request) => request.headers['authorization'] == 'Bearer abc',
          ),
          isTrue,
        );
      },
    );

    test('turns expired sessions into a session-ended failure', () async {
      final client = _repositoryClient(
        (_) async => http.Response('{"code":"INVALID_SESSION"}', 401),
      );
      addTearDown(client.close);

      await expectLater(
        ChatRepository(client).conversations('expired'),
        throwsA(
          isA<ChatFailure>()
              .having((failure) => failure.sessionEnded, 'sessionEnded', true)
              .having(
                (failure) => failure.message,
                'message',
                contains('session has ended'),
              ),
        ),
      );
    });

    test('does not expose backend details for a conflicting retry', () async {
      final client = _repositoryClient(
        (_) async => http.Response(
          '{"code":"MESSAGE_RETRY_CONFLICT","message":"internal detail"}',
          409,
        ),
      );
      addTearDown(client.close);

      await expectLater(
        ChatRepository(client).send(
          'abc',
          receiverId: 17,
          clientMessageId: 'same-id',
          content: 'changed payload',
        ),
        throwsA(
          isA<ChatFailure>()
              .having(
                (failure) => failure.message,
                'message',
                contains('could not be retried'),
              )
              .having(
                (failure) => failure.message,
                'message',
                isNot(contains('internal detail')),
              ),
        ),
      );
    });

    test('rejects malformed successful responses with a safe error', () async {
      final client = _repositoryClient(
        (_) async => http.Response('<html>oops</html>', 200),
      );
      addTearDown(client.close);

      await expectLater(
        ChatRepository(client).conversations('abc'),
        throwsA(
          isA<ChatFailure>().having(
            (failure) => failure.message,
            'message',
            'The server returned an invalid chat response.',
          ),
        ),
      );
    });
  });
}

ApiClient _repositoryClient(
  Future<http.Response> Function(http.Request) handler,
) => ApiClient(baseUrl: 'https://uniconnect.test', client: MockClient(handler));

Map<String, Object?> _messageJson({
  required int id,
  required int senderId,
  required String content,
  String clientMessageId = 'server-client-id',
  String? deliveredAt,
}) => {
  'id': id,
  'conversationId': 81,
  'senderId': senderId,
  'clientMessageId': clientMessageId,
  'content': content,
  'sentAt': '2026-10-17T08:15:00',
  'deliveredAt': deliveredAt,
  'readAt': null,
  'deletedForEveryoneAt': null,
};
