import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/model/registration.dart';

abstract interface class RegistrationRepository {
  Future<RegistrationResult> register(RegistrationRequest request);
  Future<void> resendVerification(String email);
}

class ApiRegistrationRepository implements RegistrationRepository {
  ApiRegistrationRepository(this._client);
  final ApiClient _client;

  @override
  Future<RegistrationResult> register(RegistrationRequest request) async {
    final response = await _post('/api/v1/auth/register', request.toJson());
    if (response.statusCode != 201) throw _failure(response);
    try {
      return RegistrationResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on FormatException {
      throw const RegistrationFailure(
        'The server returned an invalid response.',
      );
    } on TypeError {
      throw const RegistrationFailure(
        'The server returned an invalid response.',
      );
    }
  }

  @override
  Future<void> resendVerification(String email) async {
    final response = await _post('/api/v1/auth/resend-verification', {
      'email': email,
    });
    if (response.statusCode != 202) throw _failure(response);
  }

  Future<http.Response> _post(String path, Object body) async {
    try {
      return await _client
          .post(path, body: body)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const RegistrationFailure(
        'The request timed out. Check your inbox before retrying registration.',
      );
    } on http.ClientException {
      throw const RegistrationFailure(
        'Cannot reach UniConnect. Check your connection and try again.',
      );
    }
  }

  RegistrationFailure _failure(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final errors = <String, String>{};
      for (final item in (json['fieldErrors'] as List<dynamic>? ?? [])) {
        final field = item as Map<String, dynamic>;
        errors[field['field'] as String] = field['message'] as String;
      }
      final code = json['code'];
      if (code == 'EMAIL_ALREADY_EXISTS') {
        errors['email'] = 'An account already uses this email.';
      }
      return RegistrationFailure(
        json['message'] as String? ??
            'Unable to complete the request. Try again.',
        fieldErrors: errors,
      );
    } on Object {
      return const RegistrationFailure(
        'Unable to complete the request. Try again.',
      );
    }
  }
}
