import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/data/email_verification_repository.dart';
import 'package:uniconnect/features/authentication/model/verification_failure.dart';

void main() {
  test('posts the fragment token as JSON and accepts only 204', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/verify-email');
        expect(request.url.fragment, isEmpty);
        expect(jsonDecode(request.body), {'token': 'a' * 43});
        return http.Response('', 204);
      }),
    );
    addTearDown(client.close);
    await ApiEmailVerificationRepository(client).verify('a' * 43);
  });

  test('normalizes replacement email and accepts empty 202', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/resend-verification');
        expect(jsonDecode(request.body), {'email': 'member@iut-dhaka.edu'});
        return http.Response('', 202);
      }),
    );
    addTearDown(client.close);
    await ApiEmailVerificationRepository(client)
        .resend(' MEMBER@IUT-DHAKA.EDU ');
  });

  test('recognizes invalid tokens without exposing server details', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          '{"code":"INVALID_VERIFICATION_TOKEN","message":"private detail"}',
          400,
        ),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      ApiEmailVerificationRepository(client).verify('a' * 43),
      throwsA(
        isA<VerificationFailure>()
            .having((error) => error.invalidLink, 'invalid link', isTrue)
            .having(
              (error) => error.message,
              'safe message',
              isNot(contains('private')),
            ),
      ),
    );
  });

  test(
    'unexpected status, malformed errors and network failures never succeed',
    () async {
      for (final status in [200, 400, 503, 0]) {
        final client = ApiClient(
          client: MockClient((_) async {
            if (status == 0) throw http.ClientException('private detail');
            return http.Response('<html>private detail</html>', status);
          }),
        );
        addTearDown(client.close);
        await expectLater(
          ApiEmailVerificationRepository(client).verify('a' * 43),
          throwsA(
            isA<VerificationFailure>()
                .having((error) => error.invalidLink, 'retryable', isFalse)
                .having(
                  (error) => error.message,
                  'safe message',
                  isNot(contains('private')),
                ),
          ),
        );
      }
    },
  );
}
