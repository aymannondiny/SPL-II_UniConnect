import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/network/paged_loader.dart';
import 'package:uniconnect/features/administration/data/admin_club_repository.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/notification/data/notification_repository.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  late SessionController session;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@example.org', 'test-password');
  });
  tearDown(() => session.dispose());

  test('notifications retrieve every page with the supported size', () async {
    final pages = <int>[];
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.url.queryParameters['size'], '50');
        final page = int.parse(request.url.queryParameters['page']!);
        pages.add(page);
        return http.Response(
          jsonEncode({
            'items': [
              for (var id = page * 50; id < (page == 0 ? 50 : 51); id++)
                {
                  'id': id,
                  'type': 'REPORT_RESOLVED',
                  'title': 'Report update',
                  'message': 'Reviewed',
                  'referenceType': 'REPORT',
                  'referenceId': 12,
                  'createdAt': '2026-10-25T10:00:00',
                },
            ],
            'totalElements': 51,
          }),
          200,
        );
      }),
    );
    addTearDown(client.close);
    expect(
      await ApiNotificationRepository(client, session).list(),
      hasLength(51),
    );
    expect(pages, [0, 1]);
  });

  test(
    'eligible students and managed publications retrieve the second page',
    () async {
      final requested = <String>[];
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.method == 'PUT') return http.Response('{}', 200);
          requested.add(
            '${request.url.path}:${request.url.queryParameters['page']}',
          );
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(
            jsonEncode({
              'items': [
                for (var id = page * 50; id < (page == 0 ? 50 : 51); id++)
                  {
                    'id': id,
                    'userId': id,
                    'fullName': 'Member $id',
                    'email': 'member$id@iut-dhaka.edu',
                    'clubId': 1,
                    'clubName': 'Club',
                    'title': 'Publication $id',
                    'content': 'Content',
                    'description': 'Description',
                    'startsAt': '2026-10-25T10:00:00',
                    'endsAt': '2026-10-25T11:00:00',
                    'status': 'PUBLISHED',
                    'priority': 'NORMAL',
                    'eventType': 'WORKSHOP',
                    'visibility': 'PUBLIC',
                    'createdAt': '2026-10-25T10:00:00',
                    'updatedAt': '2026-10-25T10:00:00',
                  },
              ],
              'totalElements': 51,
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      expect(
        await AdminClubRepository(client, session).students(),
        hasLength(51),
      );
      final clubs = ClubRepository(client, session);
      expect((await clubs.managedAnnouncements(1)).items, hasLength(51));
      expect((await clubs.managedEvents(1)).items, hasLength(51));
      expect(requested.where((path) => path.endsWith(':1')), hasLength(3));
    },
  );

  test(
    'premature empty pages report inconsistency instead of silent truncation',
    () async {
      await expectLater(
        loadAllPages<int>((page) async => (items: <int>[], total: 51)),
        throwsA(isA<AuthFailure>()),
      );
    },
  );

  test('failed later page is an error rather than partial success', () async {
    await expectLater(
      loadAllPages<int>((page) async {
        if (page == 0) return (items: [1], total: 2);
        throw const AuthFailure('Retry page two.');
      }),
      throwsA(isA<AuthFailure>()),
    );
  });
}
