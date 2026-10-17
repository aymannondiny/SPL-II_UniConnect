import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/model/verification_failure.dart';

abstract interface class EmailVerificationRepository {
  Future<void> verify(String token);
  Future<void> resend(String email);
}

class ApiEmailVerificationRepository implements EmailVerificationRepository {
  ApiEmailVerificationRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> verify(String token) async {
    await _post('/api/v1/auth/verify-email', {'token': token}, 204);
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
      if (_isInvalidLink(response)) {
        throw const VerificationFailure(
          'This link has expired, has already been used, or was replaced. '
          'If you already verified your email, you can log in.',
          invalidLink: true,
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

  bool _isInvalidLink(http.Response response) {
    if (response.statusCode != 400) return false;
    try {
      final body = jsonDecode(response.body);
      return body is Map && body['code'] == 'INVALID_VERIFICATION_TOKEN';
    } on FormatException {
      return false;
    }
  }
}
