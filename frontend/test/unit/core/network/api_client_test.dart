import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';

void main() {
  test('GET resolves a relative API path and sends JSON headers', () async {
    final MockClient mockClient = MockClient((http.Request request) async {
      expect(
        request.url.toString(),
        'https://api.example.test/actuator/health',
      );
      expect(request.headers['Accept'], 'application/json');

      return http.Response('{"status":"UP"}', 200);
    });

    final ApiClient client = ApiClient(
      client: mockClient,
      baseUrl: 'https://api.example.test',
    );

    final http.Response response = await client.get('/actuator/health');

    expect(response.statusCode, 200);
    expect(jsonDecode(response.body), <String, dynamic>{'status': 'UP'});

    client.close();
  });

  test('POST encodes the request body as JSON', () async {
    final MockClient mockClient = MockClient((http.Request request) async {
      expect(request.url.toString(), 'https://api.example.test/api/auth/login');
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), <String, dynamic>{
        'email': 'student@iut-dhaka.edu',
        'password': 'example-password',
      });

      return http.Response('{"accepted":true}', 200);
    });

    final ApiClient client = ApiClient(
      client: mockClient,
      baseUrl: 'https://api.example.test',
    );

    final http.Response response = await client.post(
      '/api/auth/login',
      body: <String, dynamic>{
        'email': 'student@iut-dhaka.edu',
        'password': 'example-password',
      },
    );

    expect(response.statusCode, 200);

    client.close();
  });
}
