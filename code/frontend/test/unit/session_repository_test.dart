import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/data/auth_transport.dart';
import 'package:uniconnect/features/authentication/data/session_repository.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

void main() {
  test(
    'login/refresh are public; account/logout use the current bearer',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/me')) {
            return http.Response(
              jsonEncode({
                'userId': 12,
                'fullName': 'Test',
                'email': 'member@iut-dhaka.edu',
                'accountStatus': 'ACTIVE',
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/logout')) {
            return http.Response('', 204);
          }
          return http.Response(
            jsonEncode({
              'tokenType': 'Bearer',
              'accessToken': 'access',
              'refreshToken': 'refresh',
              'accessExpiresAt': DateTime.now()
                  .add(const Duration(minutes: 15))
                  .toUtc()
                  .toIso8601String(),
              'expiresAt': DateTime.now()
                  .add(const Duration(days: 7))
                  .toUtc()
                  .toIso8601String(),
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      final repository = ApiSessionRepository(AuthTransport(client));
      final session = await repository.login(
        ' Member@IUT-DHAKA.EDU ',
        ' pass word ',
      );
      await repository.account(session.accessToken);
      await repository.refresh(session.refreshToken);
      await repository.logout(session.accessToken);
      expect(requests.map((r) => r.url.path), [
        '/api/v1/auth/login',
        '/api/v1/auth/me',
        '/api/v1/auth/refresh',
        '/api/v1/auth/logout',
      ]);
      expect(jsonDecode(requests[0].body), {
        'email': 'member@iut-dhaka.edu',
        'password': ' pass word ',
      });
      expect(requests[0].headers['Authorization'], isNull);
      expect(requests[2].headers['Authorization'], isNull);
      expect(jsonDecode(requests[2].body), {'refreshToken': 'refresh'});
      expect(requests[1].headers['Authorization'], 'Bearer access');
      expect(requests[3].headers['Authorization'], 'Bearer access');
    },
  );

  for (final body in [
    '<html>proxy failure</html>',
    '{}',
    '{"accessToken":5}',
  ]) {
    test('rejects malformed successful session: $body', () async {
      final client = ApiClient(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(client.close);
      final repository = ApiSessionRepository(AuthTransport(client));
      await expectLater(
        repository.login('a@b.edu', 'password'),
        throwsA(isA<AuthFailure>()),
      );
    });
  }

  test(
    'invalid credentials do not disclose account state or echo server data',
    () async {
      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            '{"code":"INVALID_CREDENTIALS","message":"sensitive server data"}',
            401,
          ),
        ),
      );
      addTearDown(client.close);
      await expectLater(
        ApiSessionRepository(
          AuthTransport(client),
        ).login('a@b.edu', 'password'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            allOf(contains('Unable to log in'), isNot(contains('sensitive'))),
          ),
        ),
      );
    },
  );

  test('network failures become actionable errors', () async {
    final client = ApiClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(client.close);
    await expectLater(
      ApiSessionRepository(AuthTransport(client)).login('a@b.edu', 'password'),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Cannot reach UniConnect'),
        ),
      ),
    );
  });
}
