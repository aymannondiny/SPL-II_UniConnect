import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../model/club.dart';
import '../model/club_announcement.dart';
import '../model/club_event.dart';
import '../model/club_page.dart';

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
