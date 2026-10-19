import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/model/club_event.dart';
import 'package:uniconnect/features/club/model/publication_time.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/campus_fixture_api.dart';

void main() {
  late SessionController session;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@example.org', 'test-password');
  });
  tearDown(() => session.dispose());

  test('club reads authenticate; public publications omit credentials and encode filters', () async {
    final requests = <http.Request>[];
    final repository = ClubRepository(
      ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'items': [], 'totalElements': 0}),
            200,
          );
        }),
      ),
      session,
    );
    await repository.clubs('Arts & culture', 2);
    await repository.announcements(3, 1);
    await repository.events(3, 'ACTIVE', 0);
    await repository.events(3, 'PAST', 0);
    expect(requests.first.headers['Authorization'], startsWith('Bearer '));
    expect(requests.first.url.queryParameters['search'], 'Arts & culture');
    expect(requests.first.url.queryParameters['page'], '2');
    for (final request in requests.skip(1)) {
      expect(request.headers.containsKey('Authorization'), isFalse);
    }
    expect(requests[1].url.queryParameters['clubId'], '3');
    expect(requests[2].url.queryParameters['timing'], 'ACTIVE');
    expect(requests[3].url.path, '/api/v1/clubs/3/events/history');
    expect(requests[3].url.queryParameters.containsKey('timing'), isFalse);
  });

  test(
    'fixtures parse directory, details, feeds and history contracts',
    () async {
      final repository = ClubRepository(
        ApiClient(client: CampusFixtureApi().client),
        session,
      );
      expect((await repository.clubs('', 0)).items.length, 3);
      expect((await repository.club(1)).name, 'Programming Club');
      expect((await repository.announcements(null, 0)).items.length, 2);
      expect((await repository.announcement(11)).priority, 'IMPORTANT');
      expect((await repository.events(null, 'ALL', 0)).items.length, 3);
      expect((await repository.events(1, 'PAST', 0)).items.single.id, 24);
      expect((await repository.event(21)).location, 'Computer Lab 1');
    },
  );

  for (final response in [
    http.Response('{}', 404),
    http.Response('bad json', 200),
    http.Response('{"items":[{}],"totalElements":1}', 200),
  ]) {
    test(
      'invalid or unavailable responses return safe errors: ${response.body} ${response.statusCode}',
      () async {
        final repository = ClubRepository(
          ApiClient(client: MockClient((_) async => response)),
          session,
        );
        await expectLater(repository.clubs('', 0), throwsA(isA<AuthFailure>()));
      },
    );
  }

  test('authenticated 401 expires session', () async {
    final repository = ClubRepository(
      ApiClient(client: MockClient((_) async => http.Response('{}', 401))),
      session,
    );
    await expectLater(repository.clubs('', 0), throwsA(isA<AuthFailure>()));
    expect(session.account, isNull);
  });

  test('offset-free publication times are UTC and registration respects exact deadline', () {
    expect(
      publicationTime('2026-11-01T09:00:00').toUtc(),
      DateTime.utc(2026, 11, 1, 9),
    );
    final now = DateTime.utc(2026, 11, 1, 8);
    ClubEvent event(String url) => ClubEvent(
      id: 1,
      clubId: 1,
      clubName: 'Club',
      title: 'Event',
      description: 'Details',
      startsAt: now.add(const Duration(hours: 1)),
      endsAt: now.add(const Duration(hours: 2)),
      registrationUrl: url,
      registrationDeadline: now,
    );
    expect(event('https://example.org').registrationAt(now), isNull);
    expect(
      event('https://example.org')
          .registrationAt(now.subtract(const Duration(seconds: 1))),
      isNotNull,
    );
    for (final url in [
      'javascript:alert(1)',
      'http://example.org',
      'https://user:secret@example.org',
    ]) {
      expect(
        event(url).registrationAt(now.subtract(const Duration(seconds: 1))),
        isNull,
      );
    }
    expect(event('').timingAt(now), 'Upcoming');
    expect(event('').timingAt(now.add(const Duration(hours: 1))), 'Live now');
    expect(event('').timingAt(now.add(const Duration(hours: 3))), 'Past');
  });
}
