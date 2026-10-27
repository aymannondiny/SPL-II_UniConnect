import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

/// Shared HTTP boundary for session and password recovery contracts.
class AuthTransport {
  AuthTransport(this._client);
  final ApiClient _client;

  Future<http.Response> post(
    String path,
    Object? body,
    int success, {
    String? accessToken,
  }) {
    return _send(
      () => _client.post(path, body: body, headers: _headers(accessToken)),
      success,
    );
  }

  Future<http.Response> get(String path, String accessToken) {
    return _send(() => _client.get(path, headers: _headers(accessToken)), 200);
  }

  Map<String, String>? _headers(String? token) =>
      token == null ? null : {'Authorization': 'Bearer $token'};

  T decode<T>(http.Response response, T Function(Map<String, dynamic>) parse) {
    try {
      return parse(jsonDecode(response.body) as Map<String, dynamic>);
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid response. Try again.',
      );
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
    int success,
  ) async {
    try {
      final response = await request().timeout(const Duration(seconds: 20));
      if (response.statusCode != success) throw _failure(response);
      return response;
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please try again.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and try again.',
      );
    }
  }

  AuthFailure _failure(http.Response response) {
    String? code;
    final fields = <String, String>{};
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      code = json['code'] as String?;
      for (final item in json['fieldErrors'] as List<dynamic>? ?? []) {
        final field = item as Map<String, dynamic>;
        final name = field['field'] as String;
        // Use local messages so a server/proxy cannot echo credentials into UI.
        if (name == 'email') fields[name] = 'Enter a valid email address.';
        if (name == 'code') {
          fields[name] = 'Enter the six-digit code from your email.';
        }
        if (name == 'password') fields[name] = 'Enter your password.';
        if (name == 'newPassword') {
          fields[name] = 'Use 8–72 characters and at most 72 UTF-8 bytes.';
        }
      }
    } on Object {
      // Proxies can return non-JSON errors. Keep the fallback actionable.
    }
    final message = switch (code) {
      'INVALID_CREDENTIALS' => 'Unable to log in. Check your email and password. Your account must be verified and active.',
      'INVALID_SESSION' || 'AUTHENTICATION_REQUIRED' =>
        'Your session has ended. Please log in again.',
      'INVALID_PASSWORD_RESET_CODE' => 'The email or reset code is incorrect, expired, or already used. Request a new code if needed.',
      'INVALID_PASSWORD' => 'Use 8–72 characters and at most 72 UTF-8 bytes.',
      'VALIDATION_FAILED' => 'Check the highlighted fields and try again.',
      _ =>
        response.statusCode == 429
            ? 'Too many attempts. Please wait before trying again.'
            : 'Unable to complete the request. Please try again.',
    };
    return AuthFailure(
      message,
      fieldErrors: fields,
      sessionEnded:
          code == 'INVALID_SESSION' || code == 'AUTHENTICATION_REQUIRED',
    );
  }
}
