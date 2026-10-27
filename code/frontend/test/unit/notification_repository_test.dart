import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/notification/data/notification_repository.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  late SessionController session;

  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@example.org', 'test-password');
  });

  tearDown(() => session.dispose());

  for (final role in ['SYSTEM_ADMIN', 'STUDENT', 'ALUMNI']) {
    test(
      '$role notification visibility and bulk read respect role scope',
      () async {
        session.account = CurrentAccount(
          userId: 1,
          fullName: 'Test',
          email: 'test@iut-dhaka.edu',
          platformRole: role,
        );
        final writes = <String>[];
        final client = ApiClient(
          client: MockClient((request) async {
            if (request.method == 'PATCH') {
              writes.add(request.url.path);
              return http.Response(
                '{}',
                request.url.path.endsWith('/read') &&
                        request.url.path != '/api/v1/notifications/read'
                    ? 200
                    : 204,
              );
            }
            final page = int.parse(request.url.queryParameters['page']!);
            return http.Response(
              jsonEncode({
                'items': [
                  for (var i = page * 50; i < (page == 0 ? 50 : 51); i++)
                    {
                      'id': i + 1,
                      'type': i == 50
                          ? 'ACCOUNT_REACTIVATED'
                          : [
                              'PROJECT_APPLICATION_ACCEPTED',
                              'REPORT_RESOLVED',
                              'MENTORSHIP_SLOT_UPDATED',
                              'NEW_MESSAGE',
                              'CLUB_ROLE_GRANTED',
                            ][i % 5],
                      'title': 'Update',
                      'message': 'Details',
                      'referenceType': i == 50
                          ? 'USER'
                          : [
                              'PROJECT',
                              'REPORT',
                              'MENTORSHIP_SLOT',
                              'CONVERSATION',
                              'CLUB',
                            ][i % 5],
                      'referenceId': 1,
                      'createdAt': '2026-10-25T10:00:00',
                      'readAt': null,
                    },
                ],
                'totalElements': 51,
              }),
              200,
            );
          }),
        );
        addTearDown(client.close);
        final repository = ApiNotificationRepository(client, session);
        final items = await repository.list();
        expect(items.length, role == 'SYSTEM_ADMIN' ? 1 : 51);
        if (role == 'SYSTEM_ADMIN') expect(items.single.id, 51);
        await repository.markAllRead();
        expect(writes, [
          role == 'SYSTEM_ADMIN'
              ? '/api/v1/notifications/51/read'
              : '/api/v1/notifications/read',
        ]);
      },
    );
  }

  test(
    'lists notifications with the backend page limit and UTC timestamps',
    () async {
      late http.Request request;
      final client = ApiClient(
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 9,
                  'type': 'NEW_MESSAGE',
                  'title': 'New message from Alex',
                  'message': 'Sent you a message.',
                  'referenceType': 'CONVERSATION',
                  'referenceId': 12,
                  'createdAt': '2026-10-19T08:00:00',
                  'readAt': '2026-10-19T08:05:00',
                },
              ],
              'page': 0,
              'size': 50,
              'totalElements': 1,
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);

      final items = await ApiNotificationRepository(client, session).list();

      expect(request.url.path, '/api/v1/notifications');
      expect(request.url.queryParameters, {'page': '0', 'size': '50'});
      expect(request.headers['authorization'], 'Bearer access-login');
      expect(items.single.id, 9);
      expect(items.single.referenceId, 12);
      expect(items.single.createdAt.toUtc(), DateTime.utc(2026, 10, 19, 8));
      expect(items.single.readAt?.toUtc(), DateTime.utc(2026, 10, 19, 8, 5));
    },
  );

  test('read actions use the expected routes and response statuses', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          '',
          request.url.path.endsWith('/9/read') ? 200 : 204,
        );
      }),
    );
    addTearDown(client.close);
    final repository = ApiNotificationRepository(client, session);

    await repository.markRead(9);
    await repository.markAllRead();

    expect(requests.map((request) => request.method), ['PATCH', 'PATCH']);
    expect(requests.map((request) => request.url.path), [
      '/api/v1/notifications/9/read',
      '/api/v1/notifications/read',
    ]);
    expect(
      requests.every(
        (request) => request.headers['authorization'] == 'Bearer access-login',
      ),
      isTrue,
    );
  });

  test('an expired API session clears the authenticated account', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    addTearDown(client.close);

    await expectLater(
      ApiNotificationRepository(client, session).list(),
      throwsA(isA<AuthFailure>()),
    );

    expect(session.account, isNull);
  });
}
