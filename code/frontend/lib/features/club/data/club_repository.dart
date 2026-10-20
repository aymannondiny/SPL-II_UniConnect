import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../model/club.dart';
import '../model/club_announcement.dart';
import '../model/club_creation_request.dart';
import '../model/club_event.dart';
import '../model/club_page.dart';
import '../model/club_workspace_context.dart';

class ClubRepository {
  ClubRepository(this.client, this.session);
  final ApiClient client;
  final SessionController session;

  Future<T> _get<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    bool authenticated = false,
  }) async {
    try {
      final headers = authenticated
          ? {'Authorization': 'Bearer ${await session.accessToken()}'}
          : null;
      final response = await client
          .get(path, headers: headers)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401 && authenticated) {
        session.expire();
        throw const AuthFailure('Your session has ended. Please log in again.');
      }
      if (response.statusCode != 200) {
        throw AuthFailure(switch (response.statusCode) {
          403 => 'You do not have access to this club.',
          404 => 'This club or publication is no longer available.',
          _ => 'Unable to load campus updates. Please retry.',
        });
      }
      try {
        return parse(jsonDecode(response.body) as Map<String, dynamic>);
      } on Object {
        throw const AuthFailure(
          'The server returned an invalid campus response.',
        );
      }
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please retry.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    }
  }

  String _path(String path, int page, Map<String, String> filters) => Uri(
    path: path,
    queryParameters: {'page': '$page', 'size': '12', ...filters},
  ).toString();

  Future<Map<String, dynamic>> _write(
    String method,
    String path,
    Object body,
  ) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${await session.accessToken()}',
      };
      final response =
          await (method == 'PUT'
                  ? client.put(path, body: body, headers: headers)
                  : client.post(path, body: body, headers: headers))
              .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        session.expire();
        throw const AuthFailure('Your session has ended. Please log in again.');
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        var message = switch (response.statusCode) {
          400 => 'Check the details and try again.',
          403 => 'Your current role does not allow this action.',
          404 => 'This club or request is no longer available.',
          409 => 'The club data changed. Refresh and try again.',
          _ => 'Unable to save your changes. Please retry.',
        };
        try {
          final error = jsonDecode(response.body) as Map<String, dynamic>;
          if (error['message'] is String) message = error['message'] as String;
        } on Object {
          // Keep a status-specific message if the server body is not JSON.
        }
        throw AuthFailure(message);
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> _authenticatedJson(String path) async {
    try {
      final response = await client
          .get(
            path,
            headers: {'Authorization': 'Bearer ${await session.accessToken()}'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        session.expire();
        throw const AuthFailure('Your session has ended. Please log in again.');
      }
      if (response.statusCode != 200) {
        throw AuthFailure(
          response.statusCode == 403
              ? 'Your current role does not allow this action.'
              : 'Unable to load club information. Please retry.',
        );
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
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

  Future<List<dynamic>> _authenticatedList(String path) async {
    final response = await client
        .get(
          path,
          headers: {'Authorization': 'Bearer ${await session.accessToken()}'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      session.expire();
      throw const AuthFailure('Your session has ended. Please log in again.');
    }
    if (response.statusCode != 200) {
      throw AuthFailure(
        response.statusCode == 403
            ? 'Your current role does not allow this action.'
            : 'Unable to load club requests. Please retry.',
      );
    }
    try {
      return jsonDecode(response.body) as List<dynamic>;
    } on Object {
      throw const AuthFailure('The server returned an invalid response.');
    }
  }

  Future<List<ClubWorkspaceContext>> contexts() async {
    final json = await _authenticatedJson('/api/v1/auth/contexts');
    return (json['availableContexts'] as List<dynamic>)
        .map(
          (value) =>
              ClubWorkspaceContext.fromJson(value as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> selectContext(String type, {int? assignmentId}) async {
    await _write('PUT', '/api/v1/auth/contexts/active', {
      'contextType': type,
      'assignmentId': assignmentId,
    });
  }

  Future<List<ClubCreationRequest>> myRequests() async =>
      (await _authenticatedList('/api/v1/club-requests/mine'))
          .map(
            (value) =>
                ClubCreationRequest.fromJson(value as Map<String, dynamic>),
          )
          .toList();

  Future<ClubCreationRequest> submitRequest({
    required String name,
    required String category,
    required String description,
    String? logoUrl,
    String? contactEmail,
  }) async => ClubCreationRequest.fromJson(
    await _write('POST', '/api/v1/club-requests', {
      'clubName': name,
      'category': category,
      'description': description,
      'logoUrl': _blankToNull(logoUrl),
      'contactEmail': _blankToNull(contactEmail),
    }),
  );

  Future<void> saveProfile(
    int clubId, {
    required String name,
    required String category,
    required String description,
    String? logoUrl,
    String? contactEmail,
  }) async {
    await _write('PUT', '/api/v1/clubs/$clubId', {
      'clubName': name,
      'category': category,
      'description': description,
      'logoUrl': _blankToNull(logoUrl),
      'contactEmail': _blankToNull(contactEmail),
    });
  }

  Future<ClubPage<ClubAnnouncement>> managedAnnouncements(int clubId) async {
    final json = await _authenticatedJson(
      '/api/v1/clubs/$clubId/publications/announcements?size=50',
    );
    return ClubPage.fromJson(json, ClubAnnouncement.fromJson);
  }

  Future<ClubPage<ClubEvent>> managedEvents(int clubId) async {
    final json = await _authenticatedJson(
      '/api/v1/clubs/$clubId/publications/events?size=50',
    );
    return ClubPage.fromJson(json, ClubEvent.fromJson);
  }

  Future<void> saveAnnouncement(
    int clubId, {
    int? id,
    required String title,
    required String content,
    required String priority,
    DateTime? expiresAt,
    required bool publishNow,
  }) async {
    final body = {
      'title': title,
      'content': content,
      'priority': priority,
      'expiresAt': expiresAt == null ? null : _utcApiTime(expiresAt),
      if (id == null) 'status': publishNow ? 'PUBLISHED' : 'UNPUBLISHED',
    };
    await _write(
      id == null ? 'POST' : 'PUT',
      '/api/v1/clubs/$clubId/publications/announcements${id == null ? '' : '/$id'}',
      body,
    );
  }

  Future<void> publishAnnouncement(int clubId, int id) async => _write(
    'POST',
    '/api/v1/clubs/$clubId/publications/announcements/$id/publish',
    {},
  );
  Future<void> unpublishAnnouncement(int clubId, int id, String reason) async =>
      _write(
        'POST',
        '/api/v1/clubs/$clubId/publications/announcements/$id/unpublish',
        {'reason': reason, 'confirm': true},
      );
  Future<void> removeAnnouncement(int clubId, int id, String reason) async =>
      _write(
        'POST',
        '/api/v1/clubs/$clubId/publications/announcements/$id/remove',
        {'reason': reason, 'confirm': true},
      );

  Future<void> saveEvent(
    int clubId, {
    int? id,
    required String title,
    required String description,
    String? location,
    String? registrationUrl,
    DateTime? registrationDeadline,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'location': _blankToNull(location),
      'registrationUrl': _blankToNull(registrationUrl),
      'registrationDeadline': registrationDeadline == null
          ? null
          : _utcApiTime(registrationDeadline),
      'startsAt': _utcApiTime(startsAt),
      'endsAt': _utcApiTime(endsAt),
    };
    await _write(
      id == null ? 'POST' : 'PUT',
      '/api/v1/clubs/$clubId/publications/events${id == null ? '' : '/$id'}',
      body,
    );
  }

  Future<void> removeEvent(int clubId, int id, String reason) async => _write(
    'POST',
    '/api/v1/clubs/$clubId/publications/events/$id/remove',
    {'reason': reason, 'confirm': true},
  );

  String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
  String _utcApiTime(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}T${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}:${utc.second.toString().padLeft(2, '0')}';
  }

  Future<ClubPage<Club>> clubs(String search, int page) => _get(
    _path('/api/v1/clubs', page, {if (search.isNotEmpty) 'search': search}),
    (json) => ClubPage.fromJson(json, Club.fromJson),
    authenticated: true,
  );

  Future<Club> club(int id) =>
      _get('/api/v1/clubs/$id', Club.fromJson, authenticated: true);

  Future<ClubPage<ClubAnnouncement>> announcements(int? clubId, int page) =>
      _get(
        _path('/api/v1/announcements', page, {
          if (clubId != null) 'clubId': '$clubId',
        }),
        (json) => ClubPage.fromJson(json, ClubAnnouncement.fromJson),
      );

  Future<ClubPage<ClubEvent>> events(int? clubId, String timing, int page) =>
      _get(
        _path(
          timing == 'PAST'
              ? '/api/v1/clubs/$clubId/events/history'
              : '/api/v1/events',
          page,
          {
            if (clubId != null && timing != 'PAST') 'clubId': '$clubId',
            if (timing != 'ALL' && timing != 'PAST') 'timing': timing,
          },
        ),
        (json) => ClubPage.fromJson(json, ClubEvent.fromJson),
      );

  Future<ClubEvent> event(int id) =>
      _get('/api/v1/events/$id', ClubEvent.fromJson);
  Future<ClubAnnouncement> announcement(int id) =>
      _get('/api/v1/announcements/$id', ClubAnnouncement.fromJson);
}
