import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/connection/data/connection_repository.dart';
import 'package:uniconnect/features/connection/model/member_filters.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  late SessionController session;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@iut-dhaka.edu', 'password');
  });
  tearDown(() => session.dispose());

  test(
    'connection transport follows all pages with stable filters and auth',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'connection': {'id': page + 1, 'status': 'ACCEPTED'},
                  'otherUserId': page + 2,
                  'fullName': 'Member $page',
                },
              ],
              'totalElements': 2,
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      final rows = await ConnectionRepository(
        client,
        session,
      ).connections('ACCEPTED', 'ALL', 'Member');
      expect(rows, hasLength(2));
      expect(requests.map((r) => r.url.queryParameters['page']), ['0', '1']);
      expect(
        requests.every(
          (r) => r.headers['authorization'] == 'Bearer access-login',
        ),
        isTrue,
      );
      expect(
        requests.every((r) => r.url.queryParameters['name'] == 'Member'),
        isTrue,
      );
    },
  );

  test('discovery serializes filters and requested page', () async {
    late http.Request captured;
    final client = ApiClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response('{"items":[],"totalElements":0}', 200);
      }),
    );
    addTearDown(client.close);
    await ConnectionRepository(client, session).members(
      const MemberFilters(
        name: 'Nafisa',
        role: 'ALUMNI',
        departmentId: '1',
        skills: ' Flutter, Java ',
        company: 'Campus Labs',
        graduationYear: '2024',
      ),
      2,
    );
    expect(captured.url.queryParameters, {
      'name': 'Nafisa',
      'role': 'ALUMNI',
      'departmentId': '1',
      'skills': 'Flutter,Java',
      'company': 'Campus Labs',
      'graduationYear': '2024',
      'sort': 'NAME_ASC',
      'page': '2',
      'size': '20',
    });
  });

  test(
    'connection mutations use backend action and invitation contracts',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            '{}',
            request.url.path == '/api/v1/connections' ? 201 : 200,
          );
        }),
      );
      addTearDown(client.close);
      final repository = ConnectionRepository(client, session);
      await repository.act(7, 'accept');
      await repository.send(17, 'Hello');
      expect(requests.first.url.path, '/api/v1/connections/7/accept');
      expect(requests.every((r) => r.method == 'POST'), isTrue);
      expect(jsonDecode(requests.last.body), {
        'receiverId': 17,
        'introductoryMessage': 'Hello',
      });
    },
  );

  test('unauthorized response expires session', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    addTearDown(client.close);
    await expectLater(
      ConnectionRepository(client, session).member(2),
      throwsA(isA<AuthFailure>()),
    );
    expect(session.account, isNull);
  });

  test('non-JSON proxy errors are safe and retryable', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response('<html>Bad gateway</html>', 502),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      ConnectionRepository(client, session).member(2),
      throwsA(isA<AuthFailure>()),
    );
    expect(session.account, isNotNull);
  });

  for (final endpoint in ['conversations', 'connections']) {
    test('chat loads multiple pages of $endpoint', () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(
            jsonEncode({
              'items': [
                endpoint == 'connections'
                    ? {'otherUserId': page + 2, 'fullName': 'Member $page'}
                    : {
                        'id': page + 80,
                        'otherUserId': page + 2,
                        'otherFullName': 'Member $page',
                        'canSend': true,
                        'unreadCount': 0,
                      },
              ],
              'totalElements': 2,
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      final repository = ChatRepository(client);
      final rows = endpoint == 'connections'
          ? await repository.acceptedConnections('token')
          : await repository.conversations('token');
      expect(rows, hasLength(2));
      expect(requests.map((r) => r.url.queryParameters['page']), ['0', '1']);
    });
  }
}
