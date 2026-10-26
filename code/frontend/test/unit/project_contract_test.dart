import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/project/controller/project_finder_controller.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/model/project_models.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';

void main() {
  late SessionController session;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@example.org', 'test-password');
  });
  tearDown(() => session.dispose());

  test(
    'project-scoped candidates preserve route, filters and pagination',
    () async {
      final client = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/projects/42/candidates');
          expect(request.url.queryParameters, {
            'page': '2',
            'size': '20',
            'sort': 'NAME_ASC',
            'departmentId': '3',
            'yearOfStudy': '2',
            'projectAvailable': 'false',
          });
          expect(request.headers['Authorization'], startsWith('Bearer '));
          return http.Response(
            jsonEncode({
              'items': [
                {'userId': 7, 'fullName': 'Candidate'},
              ],
              'page': 2,
              'size': 20,
              'totalElements': 41,
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      final result = await ProjectRepository(client, session).projectCandidates(
        42,
        departmentId: 3,
        yearOfStudy: 2,
        projectAvailable: false,
        page: 2,
      );
      expect(result.items.single.userId, 7);
      expect(result.page, 2);
      expect(result.totalElements, 41);
    },
  );

  test(
    'malformed project-scoped candidates become an actionable failure',
    () async {
      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            '{"items":[{"fullName":"Missing ID"}],"totalElements":1}',
            200,
          ),
        ),
      );
      addTearDown(client.close);
      await expectLater(
        ProjectRepository(client, session).projectCandidates(42),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            contains('unexpected format'),
          ),
        ),
      );
    },
  );

  test('four backend projects and canonical team roster deserialize', () async {
    final fixture = WorkflowFixtureApi();
    final client = ApiClient(client: fixture.client);
    addTearDown(client.close);
    final repository = ProjectRepository(client, session);
    final result = await repository.browse(const ProjectBrowseFilters(), 0);
    expect(result.items, hasLength(4));
    expect(result.items.first.skills.single.id, 7);
    final members = await repository.members(1);
    expect(members.first.membershipId, 1);
    expect(members.first.memberUserId, 2);
    expect(members.last.displayName, 'Arif Hasan');
    expect((await repository.detail(1)).skills.single.name, 'Flutter');
  });

  for (final body in [
    '{}',
    '{"items":[{"id":1,"skills":[{"name":"Flutter"}]}],"totalElements":1}',
    '{"items":"wrong type","totalElements":4}',
  ]) {
    test(
      'malformed project response becomes visible controller error: $body',
      () async {
        final client = ApiClient(
          client: MockClient((_) async => http.Response(body, 200)),
        );
        addTearDown(client.close);
        final controller = ProjectFinderController(
          ProjectRepository(client, session),
        );
        addTearDown(controller.dispose);
        await controller.loadOpen();
        expect(controller.openLoading, isFalse);
        expect(controller.error, contains('unexpected format'));
        expect(controller.openProjects, isEmpty);
      },
    );
  }

  test('malformed roster becomes actionable failure', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('[{"id":1}]', 200)),
    );
    addTearDown(client.close);
    await expectLater(
      ProjectRepository(client, session).members(1),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('management retrieves application and audit pages after 50', () async {
    final requested = <String>[];
    final client = ApiClient(
      client: MockClient((request) async {
        requested.add(
          '${request.url.path}:${request.url.queryParameters['page']}',
        );
        final page = int.parse(request.url.queryParameters['page']!);
        return http.Response(
          jsonEncode({
            'items': [
              for (
                var index = page * 50;
                index < (page == 0 ? 50 : 51);
                index++
              )
                {'id': index + 1, 'projectId': 1, 'applicantUserId': index + 2},
            ],
            'page': page,
            'size': 50,
            'totalElements': 51,
          }),
          200,
        );
      }),
    );
    addTearDown(client.close);
    final repository = ProjectRepository(client, session);
    expect((await repository.applications(1)).items, hasLength(51));
    expect((await repository.audit(1)).items, hasLength(51));
    expect(
      requested,
      containsAll([
        '/api/v1/projects/1/applications:1',
        '/api/v1/projects/1/audit:1',
      ]),
    );
  });
}
