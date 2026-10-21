import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/model/project_models.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  test('ProjectCandidate parses the FR_29 minimal response', () {
    final candidate = ProjectCandidate.fromJson({
      'userId': 42,
      'fullName': 'Java Student',
      'profilePhotoUrl': null,
      'department': {'id': 3, 'code': 'CSE', 'name': 'Computer Science'},
      'programme': {'id': 7, 'name': 'BSc in CSE'},
      'yearOfStudy': 3,
      'projectAvailable': false,
      'relevantSkills': [
        {'name': 'java', 'kind': 'REQUIRED'},
        {'name': 'sql', 'kind': 'OPTIONAL'},
      ],
      'connection': {'id': 9, 'status': 'ACCEPTED', 'outgoing': true},
    });

    expect(candidate.userId, 42);
    expect(candidate.departmentName, 'Computer Science');
    expect(candidate.programmeName, 'BSc in CSE');
    expect(candidate.yearOfStudy, 3);
    expect(candidate.projectAvailable, isFalse);
    expect(candidate.skills.map((skill) => skill.name), ['java', 'sql']);
    expect(candidate.skills.map((skill) => skill.kind), [
      'REQUIRED',
      'OPTIONAL',
    ]);
    expect(candidate.connectionStatus, 'ACCEPTED');
  });

  test('candidate search sends the retained FR_29 query contract', () async {
    late http.Request captured;
    final client = ApiClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'items': <Object>[],
            'page': 1,
            'size': 20,
            'totalElements': 0,
          }),
          200,
        );
      }),
      baseUrl: 'https://uniconnect.test',
    );
    final session = SessionController(FakeSessionRepository());
    addTearDown(client.close);
    addTearDown(session.dispose);
    await session.login('student@iut-dhaka.edu', 'password');

    await ProjectRepository(client, session).candidates(
      requiredSkills: const ['Java', 'Spring'],
      optionalSkills: const ['SQL'],
      departmentId: 3,
      yearOfStudy: 2,
      projectAvailable: false,
      page: 1,
    );

    expect(captured.url.path, '/api/v1/projects/candidates');
    expect(captured.url.queryParametersAll['requiredSkills'], [
      'Java',
      'Spring',
    ]);
    expect(captured.url.queryParametersAll['optionalSkills'], ['SQL']);
    expect(captured.url.queryParameters['departmentId'], '3');
    expect(captured.url.queryParameters['yearOfStudy'], '2');
    expect(captured.url.queryParameters['projectAvailable'], 'false');
    expect(captured.url.queryParameters['sort'], 'NAME_ASC');
    expect(captured.url.queryParameters['page'], '1');
    expect(captured.url.queryParameters['size'], '20');
  });
}
