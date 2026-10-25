import 'dart:convert';

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
}
