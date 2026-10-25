import 'dart:convert';

import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile_missing.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/mentorship/data/api_mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  test('enrolled cards load current series slot summaries', () async {
    final session = SessionController(FakeSessionRepository());
    addTearDown(session.dispose);
    await session.login('member@iut-dhaka.edu', 'password');

    late http.Request request;
    final client = ApiClient(
      baseUrl: 'https://uniconnect.test',
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode([
            {
              'slotId': 42,
              'mentorProfileId': 7,
              'mentorUserId': 9,
              'mentorName': 'Ayesha Siddika',
              'topic': 'Algorithms Review',
              'description': 'Weekly problem solving',
              'scheduleType': 'WEEKLY',
              'startDate': '2026-10-30',
              'startTime': '16:00:00',
              'endTime': '17:00:00',
              'mode': 'ONLINE',
              'meetingLink': 'https://meet.example.test/algorithms',
              'capacity': 6,
              'currentMenteeCount': 2,
              'status': 'OPEN',
            },
          ]),
          200,
        );
      }),
    );
    addTearDown(client.close);

    final slots = await ApiMentorshipRepository(
      client,
      session,
    ).getMyEnrolledSlots();

    expect(request.method, 'GET');
    expect(request.url.path, '/api/v1/mentorship/slots/my-current-series');
    expect(request.headers['authorization'], 'Bearer access-login');
    expect(slots, hasLength(1));
    expect(slots.single.slotId, 42);
    expect(slots.single.topic, 'Algorithms Review');
    expect(slots.single.mentorName, 'Ayesha Siddika');
    expect(slots.single.scheduleType, ScheduleType.weekly);
    expect(slots.single.mode, SlotMode.online);
    expect(slots.single.status, SlotStatus.open);
  });
  test('reopen and history use authenticated backend routes and distinct response contracts', () async {
    final session = SessionController(FakeSessionRepository());
    addTearDown(session.dispose);
    await session.login('member@iut-dhaka.edu', 'password');
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'https://uniconnect.test',
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'slotId': 42,
              'mentorProfileId': 7,
              'mentorUserId': 9,
              'status': 'OPEN',
              'enrollmentOpen': true,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            {
              'enrollmentId': 1,
              'slotId': 42,
              'slotTopic': 'Algorithms',
              'menteeId': 2,
              'status': 'LEFT',
              'learningGoal': 'Graph theory',
            },
            {
              'enrollmentId': 2,
              'slotId': 42,
              'slotTopic': 'Algorithms',
              'menteeId': 2,
              'status': 'ACTIVE',
            },
          ]),
          200,
        );
      }),
    );
    addTearDown(client.close);
    final repository = ApiMentorshipRepository(client, session);
    expect((await repository.reopenSlot(42)).isOpen, isTrue);
    final periods = await repository.getMyParticipation();
    expect(periods.map((period) => period.enrollmentId), [1, 2]);
    expect(periods.first.learningGoal, 'Graph theory');
    expect(requests.map((request) => request.url.path), [
      '/api/v1/mentorship/slots/42/reopen',
      '/api/v1/mentorship/slots/my-participation',
    ]);
    expect(
      requests.every(
        (request) => request.headers['authorization'] == 'Bearer access-login',
      ),
      isTrue,
    );
  });

  for (final status in [404, 503]) {
    test(
      'own mentor profile distinguishes absent registration from outage $status',
      () async {
        final session = SessionController(FakeSessionRepository());
        addTearDown(session.dispose);
        await session.login('member@iut-dhaka.edu', 'password');
        final client = ApiClient(
          baseUrl: 'https://uniconnect.test',
          client: MockClient((_) async => http.Response('{}', status)),
        );
        addTearDown(client.close);
        final repository = ApiMentorshipRepository(client, session);
        await expectLater(
          repository.getMyMentorProfile(),
          throwsA(
            status == 404
                ? isA<MentorProfileMissing>()
                : isA<AuthFailure>().having(
                    (error) => error is MentorProfileMissing,
                    'not missing',
                    isFalse,
                  ),
          ),
        );
      },
    );
  }
}
