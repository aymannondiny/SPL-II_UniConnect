import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/profile/model/academic_catalog.dart';
import 'package:uniconnect/features/profile/model/personal_profile.dart';

abstract interface class ProfileRepository {
  Future<PersonalProfile?> load();
  Future<AcademicCatalog> catalog();
  Future<PersonalProfile> save(String role, Map<String, dynamic> fields);
  Future<String> visibility();
  Future<void> saveVisibility(String visibility);
}

/// Authenticated owner endpoints; missing profiles are distinct from failures.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this.client, this.session);
  final ApiClient client;
  final SessionController session;
  static const _path = '/api/v1/profile';

  Future<http.Response> _request(
    String method,
    String path, {
    Object? body,
    bool missingAllowed = false,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${await session.accessToken()}',
      };
      final response = await switch (method) {
        'PUT' => client.put(path, body: body, headers: headers),
        'PATCH' => client.patch(path, body: body, headers: headers),
        _ => client.get(path, headers: headers),
      }.timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        session.expire();
        throw const AuthFailure(
          'Your session has ended. Please log in again.',
          sessionEnded: true,
        );
      }
      if (response.statusCode == 404 && missingAllowed) return response;
      if (response.statusCode != 200) {
        final message = switch (response.statusCode) {
          400 => 'Some profile details are invalid or the academic options changed. Review your fields and reload if needed.',
          403 => 'Your account does not have permission for this profile.',
          409 => 'These details conflict with an existing record. Check your student number or reload and try again.',
          429 => 'Too many requests. Please wait and try again.',
          _ => 'Unable to load or save your profile. Please try again.',
        };
        throw AuthFailure(message);
      }
      return response;
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please try again.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    }
  }

  T _decode<T>(http.Response response, T Function(Map<String, dynamic>) parse) {
    try {
      return parse(jsonDecode(response.body) as Map<String, dynamic>);
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid response. Please retry.',
      );
    }
  }

  @override
  Future<PersonalProfile?> load() async {
    final response = await _request('GET', '$_path/me', missingAllowed: true);
    return response.statusCode == 404
        ? null
        : _decode(response, PersonalProfile.fromJson);
  }

  @override
  Future<AcademicCatalog> catalog() async => _decode(
    await _request('GET', '$_path/academic-options'),
    AcademicCatalog.fromJson,
  );
  @override
  Future<PersonalProfile> save(
    String role,
    Map<String, dynamic> fields,
  ) async => _decode(
    await _request('PUT', '$_path/me/${role.toLowerCase()}', body: fields),
    PersonalProfile.fromJson,
  );
  @override
  Future<String> visibility() async =>
      _decode(await _request('GET', '$_path/me/privacy'), _visibility);

  String _visibility(Map<String, dynamic> json) {
    final value = json['detailsVisibility'] as String;
    if (!['ALL_MEMBERS', 'CONNECTIONS_ONLY'].contains(value)) {
      throw const FormatException('Unsupported visibility');
    }
    return value;
  }

  @override
  Future<void> saveVisibility(String visibility) async {
    final response = await _request(
      'PATCH',
      '$_path/me/privacy',
      body: {'detailsVisibility': visibility},
    );
    if (_decode(response, _visibility) != visibility) {
      throw const AuthFailure('Privacy was not updated. Please retry.');
    }
  }
}
