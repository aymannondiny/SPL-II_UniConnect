import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/administration/model/club_administration_entry.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/club/model/club.dart';
import 'package:uniconnect/features/club/model/club_creation_request.dart';
import 'package:uniconnect/features/club/model/club_page.dart';

class AdminClubRepository {
  AdminClubRepository(this.client, this.session);
  final ApiClient client;
  final SessionController session;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
    bool clubLifecycleAction = false,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${await session.accessToken()}',
      };
      final response = switch (method) {
        'POST' => client.post(path, body: body ?? {}, headers: headers),
        'PUT' => client.put(path, body: body ?? {}, headers: headers),
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
      final expected =
          method == 'POST' &&
              (path.endsWith('/clubs') || path.endsWith('/administrators'))
          ? 201
          : 200;
      if (result.statusCode != expected) {
        var message = switch (result.statusCode) {
          400 => 'Check the club details and try again.',
          403 => 'Only system administrators can manage clubs.',
          404 => 'This club or request is no longer available.',
          409 => 'This operation conflicts with the current club state.',
          _ => 'Unable to complete the club administration request.',
        };
        try {
          final error = jsonDecode(result.body) as Map<String, dynamic>;
          if (clubLifecycleAction &&
              error['code'] == 'RESOURCE_NOT_FOUND' &&
              error['message'] == 'The requested resource was not found.') {
            message = 'The running backend is missing this club action. Restart it to load the latest archive and delete endpoints, then retry.';
          } else if (error['message'] is String) {
            message = error['message'] as String;
          }
        } on Object {
          // Keep the status-specific message if the server does not return JSON.
        }
        throw AuthFailure(message);
      }
      return result.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(result.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please retry.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    } on FormatException {
      throw const AuthFailure(
        'The server returned an invalid club administration response.',
      );
    }
  }

  Future<void> _ensureSystemContext() async {
    await _request(
      'PUT',
      '/api/v1/auth/contexts/active',
      body: {'contextType': 'SYSTEM_ADMINISTRATION', 'assignmentId': null},
    );
  }

  Future<ClubPage<ClubAdministrationEntry>> clubs({
    String search = '',
    int page = 0,
  }) async {
    await _ensureSystemContext();
    final path = Uri(
      path: '/api/v1/admin/clubs',
      queryParameters: {'search': search, 'page': '$page', 'size': '50'},
    ).toString();
    final data = await _request('GET', path);
    return ClubPage.fromJson(data, ClubAdministrationEntry.fromJson);
  }

  Future<List<EligibleClubAdministrator>> students({String search = ''}) async {
    await _ensureSystemContext();
    final path = Uri(
      path: '/api/v1/admin/clubs/eligible-students',
      queryParameters: {'search': search, 'page': '0', 'size': '50'},
    ).toString();
    final data = await _request('GET', path);
    return (data['items'] as List<dynamic>)
        .map(
          (row) =>
              EligibleClubAdministrator.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ClubCreationRequest>> requests({String? status}) async {
    await _ensureSystemContext();
    final path = Uri(
      path: '/api/v1/admin/club-requests',
      queryParameters: {'status': ?status},
    ).toString();
    final response = await _list(path);
    return response
        .map((row) => ClubCreationRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> _list(String path) async {
    try {
      final response = await client
          .get(
            path,
            headers: {'Authorization': 'Bearer ${await session.accessToken()}'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        session.expire();
        throw const AuthFailure(
          'Your session has ended. Please log in again.',
          sessionEnded: true,
        );
      }
      if (response.statusCode != 200) {
        throw const AuthFailure('Unable to load club requests. Please retry.');
      }
      return jsonDecode(response.body) as List<dynamic>;
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please retry.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    } on FormatException {
      throw const AuthFailure('The server returned an invalid response.');
    }
  }

  Future<Club> createClub({
    required String name,
    required String category,
    required String description,
    required List<int> administratorIds,
    String? logoUrl,
    String? contactEmail,
  }) async {
    await _ensureSystemContext();
    final data = await _request(
      'POST',
      '/api/v1/admin/clubs',
      body: {
        'clubName': name,
        'category': category,
        'description': description,
        'logoUrl': _blankToNull(logoUrl),
        'contactEmail': _blankToNull(contactEmail),
        'administratorUserId': administratorIds.first,
        'administratorUserIds': administratorIds,
      },
    );
    return Club.fromJson(data);
  }

  Future<void> editClub(
    int id, {
    required String name,
    required String category,
    required String description,
    String? logoUrl,
    String? contactEmail,
  }) async {
    await _ensureSystemContext();
    await _request(
      'PUT',
      '/api/v1/admin/clubs/$id',
      body: {
        'clubName': name,
        'category': category,
        'description': description,
        'logoUrl': _blankToNull(logoUrl),
        'contactEmail': _blankToNull(contactEmail),
      },
    );
  }

  Future<void> assignAdministrator(int clubId, int userId) async {
    await _ensureSystemContext();
    await _request(
      'POST',
      '/api/v1/admin/clubs/$clubId/administrators',
      body: {'userId': userId},
    );
  }

  Future<void> removeAdministrator(
    int clubId,
    int assignmentId,
    String reason,
  ) async {
    await _ensureSystemContext();
    await _request(
      'POST',
      '/api/v1/admin/clubs/$clubId/administrators/$assignmentId/remove',
      body: {'reason': reason, 'confirmed': true},
    );
  }

  Future<void> decideRequest(
    int id, {
    required bool approve,
    String? reason,
  }) async {
    await _ensureSystemContext();
    await _request(
      'POST',
      '/api/v1/admin/club-requests/$id/${approve ? 'approve' : 'reject'}',
      body: approve ? {} : {'reason': _blankToNull(reason)},
    );
  }

  Future<void> lifecycle(int id, String action, String reason) async {
    await _ensureSystemContext();
    await _request(
      'POST',
      '/api/v1/admin/clubs/$id/$action',
      body: {'reason': reason, 'confirm': true},
      clubLifecycleAction: true,
    );
  }

  String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
