import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/network/response_parser.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

class AuthenticatedJsonClient {
  AuthenticatedJsonClient(this.client, this.session);

  final ApiClient client;
  final SessionController session;

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${await session.accessToken()}',
      };
      final response = await switch (method) {
        'POST' => client.post(path, headers: headers, body: body),
        'PUT' => client.put(path, headers: headers, body: body),
        _ => client.get(path, headers: headers),
      }.timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        session.expire();
        throw const AuthFailure(
          'Your session has ended. Please log in again.',
          sessionEnded: true,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = switch (response.statusCode) {
          403 => 'You do not have permission for this action.',
          404 => 'This item is no longer available or accessible.',
          409 => 'This item changed. Refresh and try again.',
          _ => 'Unable to complete the request. Please retry.',
        };
        try {
          final error = jsonDecode(response.body) as Map<String, dynamic>;
          if ({400, 409}.contains(response.statusCode) &&
              error['message'] is String) {
            message = error['message'] as String;
          }
        } on Object {
          // A non-JSON error still has a useful status-specific explanation.
        }
        throw AuthFailure(message);
      }
      return parseResponse<Map<String, dynamic>>(
        () => jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please retry.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    }
  }

  Future<void> selectAdministration() async {
    await request(
      '/api/v1/auth/contexts/active',
      method: 'PUT',
      body: {'contextType': 'SYSTEM_ADMINISTRATION', 'assignmentId': null},
    );
  }
}
