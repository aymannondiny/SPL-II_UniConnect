import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/data/auth_transport.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/model/password_reset_validation.dart';

void main() {
  test(
    'recovery sends exact public contracts without changing passwords',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            '',
            request.url.path.endsWith('forgot-password') ? 202 : 204,
          );
        }),
      );
      addTearDown(client.close);
      final repository = ApiPasswordRecoveryRepository(AuthTransport(client));
      await repository.requestCode(' Member@IUT-DHAKA.EDU ');
      await repository.reset(
        'Member@IUT-DHAKA.EDU',
        '012345',
        ' new password ',
      );
      expect(requests[0].url.path, '/api/v1/auth/forgot-password');
      expect(jsonDecode(requests[0].body), {'email': 'member@iut-dhaka.edu'});
      expect(requests[1].url.path, '/api/v1/auth/reset-password');
      await repository.verifyCode(' Member@IUT-DHAKA.EDU ', '012345');
      expect(requests[2].url.path, '/api/v1/auth/verify-password-reset-code');
      expect(jsonDecode(requests[2].body), {
        'email': 'member@iut-dhaka.edu',
        'code': '012345',
      });
      expect(jsonDecode(requests[1].body), {
        'email': 'member@iut-dhaka.edu',
        'code': '012345',
        'newPassword': ' new password ',
      });
      expect(
        requests.every(
          (request) => !request.headers.containsKey('Authorization'),
        ),
        isTrue,
      );
    },
  );

  test('expired reset codes get a recovery message', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async =>
            http.Response('{"code":"INVALID_PASSWORD_RESET_CODE"}', 400),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      ApiPasswordRecoveryRepository(AuthTransport(client))
          .reset('Member@IUT-DHAKA.EDU', '012345', 'password'),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Request a new code'),
        ),
      ),
    );
  });

  test('reset password observes character and BCrypt UTF-8 limits', () {
    expect(PasswordResetValidation.password('R7!mQ2#vL9@x'), isNull);
    expect(PasswordResetValidation.password('short'), isNotNull);
    expect(PasswordResetValidation.password('a' * 73), isNotNull);
    expect(PasswordResetValidation.password('éøßñüç' * 6), isNotNull);
    expect(PasswordResetValidation.password('é' * 37), isNotNull);
  });
}
