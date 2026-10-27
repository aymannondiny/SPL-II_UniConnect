import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/model/verification_failure.dart';

abstract interface class EmailVerificationRepository {
  Future<void> verify(String email, String code);
  Future<void> resend(String email);
}

class ApiEmailVerificationRepository implements EmailVerificationRepository {
  ApiEmailVerificationRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> verify(String email, String code) async {
    await _post('/api/v1/auth/verify-email', {
      'email': email.trim().toLowerCase(),
      'code': code,
    }, 204);
  }

  @override
  Future<void> resend(String email) async {
    await _post('/api/v1/auth/resend-verification', {
      'email': email.trim().toLowerCase(),
    }, 202);
  }

  Future<void> _post(String path, Object body, int successStatus) async {
    try {
      final response = await _client
          .post(path, body: body)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == successStatus) return;
      if (_isInvalidCode(response)) {
        throw const VerificationFailure(
          'This code is incorrect or no longer usable. Request a new code if needed. '
          'Check your email address and use the latest code.',
          invalidCode: true,
        );
      }
      throw const VerificationFailure(
        'We could not complete your request. Please try again shortly.',
      );
    } on TimeoutException {
      throw const VerificationFailure(
        'The server took too long to respond. Please try again. '
        'If verification already completed, you can log in.',
      );
    } on http.ClientException {
      throw const VerificationFailure(
        'Cannot reach UniConnect. Check your connection and try again.',
      );
    }
  }

  bool _isInvalidCode(http.Response response) {
    if (response.statusCode != 400) return false;
    try {
      final body = jsonDecode(response.body);
      return body is Map && body['code'] == 'INVALID_VERIFICATION_CODE';
    } on FormatException {
      return false;
    }
  }
}
