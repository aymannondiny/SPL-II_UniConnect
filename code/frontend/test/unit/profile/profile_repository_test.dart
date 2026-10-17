import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/profile/data/profile_repository.dart';

import '../../../tool/support/fake_session_repository.dart';
import '../../../tool/support/fake_profile_repository.dart';

void main() {
  late SessionController session;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@iut-dhaka.edu', 'password');
  });
  tearDown(() => session.dispose());
  test(
    'only owner 404 means missing; bearer rotates on subsequent calls',
    () async {
      final tokens = <String?>[];
      final client = ApiClient(
        client: MockClient((request) async {
          tokens.add(request.headers['Authorization']);
          return http.Response('', 404);
        }),
      );
      addTearDown(client.close);
      final repository = ApiProfileRepository(client, session);
      expect(await repository.load(), isNull);
      await session.refresh();
      expect(await repository.load(), isNull);
      expect(tokens, ['Bearer access-login', 'Bearer access-rotated']);
      await expectLater(repository.catalog(), throwsA(isA<AuthFailure>()));
    },
  );
  test(
    'student and alumni PUTs and privacy PATCH match the backend contract',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/privacy')
                  ? {'detailsVisibility': 'ALL_MEMBERS'}
                  : FakeProfileRepository.fixture(
                      role: request.url.path.endsWith('/alumni')
                          ? 'ALUMNI'
                          : 'STUDENT',
                    ).json,
            ),
            200,
          );
        }),
      );
      addTearDown(client.close);
      final repository = ApiProfileRepository(client, session);
      await repository.save('STUDENT', {
        'fullName': 'Member',
        'skills': [],
        'interests': [],
      });
      await repository.save('ALUMNI', {'graduationYear': 2024});
      await repository.saveVisibility('ALL_MEMBERS');
      expect(requests.map((r) => r.method), ['PUT', 'PUT', 'PATCH']);
      expect(requests.map((r) => r.url.path), [
        '/api/v1/profile/me/student',
        '/api/v1/profile/me/alumni',
        '/api/v1/profile/me/privacy',
      ]);
      expect(jsonDecode(requests.last.body), {
        'detailsVisibility': 'ALL_MEMBERS',
      });
    },
  );
  for (final body in ['{}', '<html>proxy</html>', '{"fullName":5}']) {
    test('invalid owner response is safely rejected: $body', () async {
      final client = ApiClient(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(client.close);
      await expectLater(
        ApiProfileRepository(client, session).load(),
        throwsA(isA<AuthFailure>()),
      );
    });
  }
  for (final status in [400, 403, 409, 500]) {
    test(
      'HTTP $status remains an error and never becomes onboarding',
      () async {
        final client = ApiClient(
          client: MockClient(
            (_) async => http.Response('{"message":"secret"}', status),
          ),
        );
        addTearDown(client.close);
        await expectLater(
          ApiProfileRepository(client, session).load(),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.message,
              'safe message',
              isNot(contains('secret')),
            ),
          ),
        );
      },
    );
  }
  test('401 expires app session', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('', 401)),
    );
    addTearDown(client.close);
    await expectLater(
      ApiProfileRepository(client, session).load(),
      throwsA(isA<AuthFailure>()),
    );
    expect(session.account, isNull);
  });
}
