import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/administration/model/admin_academic_catalog.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

class AdminCatalogRepository {
  AdminCatalogRepository(this.client, this.session);
  final ApiClient client;
  final SessionController session;
  static const _path = '/api/v1/admin/academics';

  Future<http.Response> _request(
    String method,
    String path, {
    Object? body,
  }) async {
    try {
      final token = await session.accessToken();
      final headers = {'Authorization': 'Bearer $token'};
      final context = await client
          .put(
            '/api/v1/auth/contexts/active',
            body: {
              'contextType': 'SYSTEM_ADMINISTRATION',
              'assignmentId': null,
            },
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      if (context.statusCode == 401) {
        session.expire();
        throw const AuthFailure(
          'Your session has ended. Please log in again.',
          sessionEnded: true,
        );
      }
      if (context.statusCode != 200) {
        throw const AuthFailure(
          'Only system administrators can manage the academic catalog.',
        );
      }
      final response = switch (method) {
        'POST' => client.post(path, body: body, headers: headers),
        'PUT' => client.put(path, body: body, headers: headers),
        _ => client.get(path, headers: headers),
      };
      final result = await response.timeout(const Duration(seconds: 20));
      if (result.statusCode == 401) {
        session.expire();
        throw const AuthFailure(
          'Your session has ended. Please log in again.',
          sessionEnded: true,
        );
      }
      final expected = method == 'POST' ? 201 : 200;
      if (result.statusCode != expected) {
        var message = switch (result.statusCode) {
          400 => 'Check the academic catalog details and try again.',
          403 => 'Only system administrators can manage the academic catalog.',
          409 => 'This catalog change conflicts with an existing record.',
          _ => 'Unable to reach the academic catalog. Please try again.',
        };
        try {
          final error = jsonDecode(result.body) as Map<String, dynamic>;
          if (error['message'] is String) message = error['message'] as String;
        } on Object {
          // Use the safe status-specific message when no API error is present.
        }
        throw AuthFailure(message);
      }
      return result;
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please try again.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    }
  }

  Future<AdminAcademicCatalog> list() async {
    final result = await _request('GET', _path);
    try {
      return AdminAcademicCatalog.fromJson(
        jsonDecode(result.body) as Map<String, dynamic>,
      );
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid academic catalog response.',
      );
    }
  }

  Future<void> saveDepartment(String name, String code, {int? id}) async {
    await _request(
      id == null ? 'POST' : 'PUT',
      id == null ? '$_path/departments' : '$_path/departments/$id',
      body: {'name': name, 'code': code},
    );
  }

  Future<void> saveProgramme(
    String name,
    String code,
    int departmentId, {
    int? id,
  }) async {
    await _request(
      id == null ? 'POST' : 'PUT',
      id == null ? '$_path/programmes' : '$_path/programmes/$id',
      body: {'name': name, 'code': code, 'departmentId': departmentId},
    );
  }

  Future<void> saveDegree({
    required int programmeId,
    required String level,
    required int durationYears,
    required int minimumYear,
    required int maximumYear,
    required bool active,
    int? id,
  }) async {
    await _request(
      id == null ? 'POST' : 'PUT',
      id == null ? '$_path/degrees' : '$_path/degrees/$id',
      body: {
        'programmeId': programmeId,
        'degreeLevel': level,
        'durationYears': durationYears,
        'minimumYear': minimumYear,
        'maximumYear': maximumYear,
        'active': active,
      },
    );
  }
}
