import 'dart:async';
import 'dart:convert';

import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile_missing.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/mentorship/data/api_mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/create_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentor_registration_request.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/update_slot_request.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  void checkMutationBody(
    String name, {
    required String method,
    required String path,
    required Map<String, dynamic> expectedBody,
    required Future<Object> Function(ApiMentorshipRepository) send,
    required Map<String, dynamic> response,
    int responseStatus = 200,
  }) {
    test(name, () async {
      final session = SessionController(FakeSessionRepository());
      addTearDown(session.dispose);
      await session.login('member@iut-dhaka.edu', 'password');
      final client = ApiClient(
        baseUrl: 'https://uniconnect.test',
        client: MockClient((request) async {
          expect(request.method, method);
          expect(request.url.path, path);
          expect(request.headers['authorization'], 'Bearer access-login');
          expect(request.headers['content-type'], contains('application/json'));
          expect(jsonDecode(request.body), expectedBody);
          return http.Response(jsonEncode(response), responseStatus);
        }),
      );
      addTearDown(client.close);
      await send(ApiMentorshipRepository(client, session));
    });
  }

  const registration = MentorRegistrationRequest(
    mentoringBio: 'I am good at math and physics',
    expertise: [MentorExpertiseInput(topic: 'math')],
  );
  const mentorResponse = <String, dynamic>{
    'mentorProfileId': 7,
    'userId': 9,
    'fullName': 'Test Mentor',
    'role': 'STUDENT',
    'status': 'AVAILABLE',
    'expertise': <dynamic>[],
  };

  for (final recovery in [
    'timeout',
    'already registered',
    'not confirmed',
    'forbidden',
  ]) {
    test('mentor registration handles $recovery without reposting', () async {
      final session = SessionController(FakeSessionRepository());
      addTearDown(session.dispose);
      await session.login('member@iut-dhaka.edu', 'password');
      final calls = <String>[];
      final pendingResponse = Completer<http.Response>();
      addTearDown(() {
        if (!pendingResponse.isCompleted) {
          pendingResponse.complete(
            http.Response(jsonEncode(mentorResponse), 201),
          );
        }
      });
      final client = ApiClient(
        baseUrl: 'https://uniconnect.test',
        client: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.method == 'POST') {
            if (recovery == 'forbidden') {
              return http.Response('{"message":"Not eligible"}', 403);
            }
            if (recovery == 'already registered') {
              return http.Response('{"code":"MENTOR_ALREADY_REGISTERED"}', 409);
            }
            return pendingResponse.future;
          }
          return recovery == 'not confirmed'
              ? http.Response('{}', 404)
              : http.Response(jsonEncode(mentorResponse), 200);
        }),
      );
      addTearDown(client.close);
      final repository = ApiMentorshipRepository(
        client,
        session,
        registrationTimeout: const Duration(milliseconds: 5),
      );
      if (recovery == 'not confirmed' || recovery == 'forbidden') {
        await expectLater(
          repository.registerAsMentor(registration),
          throwsA(
            isA<AuthFailure>().having(
              (failure) => failure.message,
              'message',
              contains(
                recovery == 'forbidden' ? 'Not eligible' : 'could not confirm',
              ),
            ),
          ),
        );
      } else {
        expect(
          (await repository.registerAsMentor(registration)).mentorProfileId,
          7,
        );
      }
      expect(calls, [
        'POST /api/v1/mentorship/mentors',
        if (recovery != 'forbidden') 'GET /api/v1/mentorship/mentors/me',
      ]);
    });
  }
  checkMutationBody(
    'mentor registration sends a JSON object with optional description omitted',
    method: 'POST',
    path: '/api/v1/mentorship/mentors',
    expectedBody: {
      'mentoringBio': 'I am good at math and physics',
      'expertise': [
        {'topic': 'math'},
      ],
    },
    send: (repository) => repository.registerAsMentor(registration),
    response: mentorResponse,
    responseStatus: 201,
  );
  checkMutationBody(
    'mentor availability sends a JSON object',
    method: 'PATCH',
    path: '/api/v1/mentorship/mentors/me/status',
    expectedBody: {'status': 'UNAVAILABLE'},
    send: (repository) =>
        repository.updateMentorStatus(MentorStatus.unavailable),
    response: {...mentorResponse, 'status': 'UNAVAILABLE'},
  );

  const slotRequest = CreateSlotRequest(
    topic: 'Math and Physics',
    description: 'Study Newton\'s laws and solve "why?" questions.',
    scheduleType: ScheduleType.weekly,
    startDate: '2026-11-05',
    startTime: '14:00:00',
    endTime: '15:00:00',
    meetingCount: 4,
    mode: SlotMode.online,
    meetingLink: 'https://meet.example.test/math',
    capacity: 5,
  );
  const slotResponse = <String, dynamic>{
    'slotId': 42,
    'mentorProfileId': 7,
    'mentorUserId': 9,
    'status': 'OPEN',
  };
  checkMutationBody(
    'publishing a session sends a JSON object and preserves quoted text',
    method: 'POST',
    path: '/api/v1/mentorship/slots',
    expectedBody: slotRequest.toJson(),
    send: (repository) => repository.createSlot(slotRequest),
    response: slotResponse,
    responseStatus: 201,
  );
  checkMutationBody(
    'editing a session sends a JSON object',
    method: 'PUT',
    path: '/api/v1/mentorship/slots/42',
    expectedBody: slotRequest.toJson(),
    send: (repository) =>
        repository.updateSlot(42, UpdateSlotRequest.fromCreate(slotRequest)),
    response: slotResponse,
  );
  checkMutationBody(
    'joining a session sends a JSON object',
    method: 'POST',
    path: '/api/v1/mentorship/slots/42/join',
    expectedBody: {
      'joinMessage': 'I would like to join',
      'learningGoal': 'Math',
    },
    send: (repository) => repository.joinSlot(
      42,
      const EnrollSlotRequest(
        joinMessage: 'I would like to join',
        learningGoal: 'Math',
      ),
    ),
    response: {
      'enrollmentId': 1,
      'slotId': 42,
      'menteeId': 2,
      'status': 'ACTIVE',
    },
  );

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
