import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/administration/data/admin_club_repository.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  late SessionController session;

  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('admin@iut-dhaka.edu', 'password');
  });

  tearDown(() => session.dispose());

  test(
    'archive and delete use their separate administration endpoints',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://uniconnect.test',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        }),
      );
      addTearDown(client.close);
      final repository = AdminClubRepository(client, session);

      await repository.lifecycle(42, 'archive', 'Temporarily inactive');
      await repository.lifecycle(42, 'delete', 'No longer required');

      final actions = requests
          .where((request) => request.method == 'POST')
          .toList();
      expect(actions.map((request) => request.url.path), [
        '/api/v1/admin/clubs/42/archive',
        '/api/v1/admin/clubs/42/delete',
      ]);
      expect(jsonDecode(actions.first.body), {
        'reason': 'Temporarily inactive',
        'confirm': true,
      });
      expect(jsonDecode(actions.last.body), {
        'reason': 'No longer required',
        'confirm': true,
      });
    },
  );

  test(
    'missing lifecycle route gives an actionable backend restart message',
    () async {
      final client = ApiClient(
        baseUrl: 'https://uniconnect.test',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/contexts/active')) {
            return http.Response('{}', 200);
          }
          return http.Response(
            jsonEncode({
              'code': 'RESOURCE_NOT_FOUND',
              'message': 'The requested resource was not found.',
            }),
            404,
          );
        }),
      );
      addTearDown(client.close);
      final repository = AdminClubRepository(client, session);

      await expectLater(
        repository.lifecycle(42, 'archive', 'Temporarily inactive'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            contains(
              'Restart it to load the latest archive and delete endpoints',
            ),
          ),
        ),
      );
    },
  );
}
