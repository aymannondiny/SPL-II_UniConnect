import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/data/registration_repository.dart';
import 'package:uniconnect/features/authentication/model/registration.dart';
import 'package:uniconnect/features/authentication/model/registration_validation.dart';

void main() {
  const request = RegistrationRequest(
    fullName: ' Ayman ',
    email: ' AYMAN@IUT-DHAKA.EDU ',
    password: 'password123',
    role: RegistrationRole.alumni,
  );

  test(
    'uses canonical request and pending response without creating a session',
    () async {
      final client = ApiClient(
        client: MockClient((incoming) async {
          expect(incoming.url.path, '/api/v1/auth/register');
          expect(jsonDecode(incoming.body), {
            'fullName': 'Ayman',
            'email': 'ayman@iut-dhaka.edu',
            'password': 'password123',
            'platformRole': 'ALUMNI',
          });
          return http.Response(
            jsonEncode({
              'userId': 42,
              'fullName': 'Ayman',
              'email': 'ayman@iut-dhaka.edu',
              'platformRole': 'ALUMNI',
              'accountStatus': 'PENDING_VERIFICATION',
            }),
            201,
          );
        }),
      );
      addTearDown(client.close);
      final result = await ApiRegistrationRepository(client).register(request);
      expect(result.accountStatus, 'PENDING_VERIFICATION');
      expect(result.email, 'ayman@iut-dhaka.edu');
    },
  );

  test('maps duplicate email and structured field errors', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'EMAIL_ALREADY_EXISTS',
            'message': 'Email already registered.',
            'fieldErrors': [
              {'field': 'fullName', 'message': 'Name is required.'},
            ],
          }),
          409,
        ),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      ApiRegistrationRepository(client).register(request),
      throwsA(
        isA<RegistrationFailure>()
            .having(
              (error) => error.fieldErrors['email'],
              'email error',
              isNotNull,
            )
            .having(
              (error) => error.fieldErrors['fullName'],
              'name error',
              'Name is required.',
            ),
      ),
    );
  });

  test('resend accepts the documented empty 202 response', () async {
    final client = ApiClient(
      client: MockClient((incoming) async {
        expect(incoming.url.path, '/api/v1/auth/resend-verification');
        return http.Response('', 202);
      }),
    );
    addTearDown(client.close);
    await ApiRegistrationRepository(client)
        .resendVerification('a@iut-dhaka.edu');
  });

  test('invalid response and network failure are safe to display', () async {
    for (final networkFailure in [false, true]) {
      final client = ApiClient(
        client: MockClient((_) async {
          if (networkFailure) {
            throw http.ClientException('private transport detail');
          }
          return http.Response('invalid json', 201);
        }),
      );
      addTearDown(client.close);
      await expectLater(
        ApiRegistrationRepository(client).register(request),
        throwsA(isA<RegistrationFailure>()),
      );
    }
  });

  test('validation follows the backend domain and password limits', () {
    expect(
      RegistrationValidation.email('a@iut-dhaka.edu.evil.test'),
      isNotNull,
    );
    expect(RegistrationValidation.email(' A@IUT-DHAKA.EDU '), isNull);
    expect(RegistrationValidation.fullName('  '), isNotNull);
    expect(RegistrationValidation.password('1234567'), isNotNull);
    expect(RegistrationValidation.password('a' * 73), isNotNull);
    expect(RegistrationValidation.password('a' * 8), isNull);
  });
}
