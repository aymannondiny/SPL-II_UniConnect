import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../model/connection_models.dart';
import '../model/member_filters.dart';

/// Owns authenticated member/connection transport, independent of widget state.
class ConnectionRepository {
  ConnectionRepository(this._client, this.session);
  final ApiClient _client;
  final SessionController session;
  Future<Map<String, String>> get _headers async => {
    'Authorization': 'Bearer ${await session.accessToken()}',
  };

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() send, {
    Set<int> accepted = const {200},
  }) async {
    try {
      final response = await send().timeout(const Duration(seconds: 20));
      if (!accepted.contains(response.statusCode)) {
        if (response.statusCode == 401) {
          session.expire();
          throw const AuthFailure(
            'Your session has ended. Please log in again.',
            sessionEnded: true,
          );
        }
        String message = switch (response.statusCode) {
          400 => 'Please check the request details and try again.',
          403 => 'You cannot perform this action for that connection.',
          404 => 'That member or connection is no longer available.',
          409 => 'That request conflicts with the current connection status. Refresh and try again.',
          _ => 'Unable to reach the connections service. Please retry.',
        };
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['message'] is String &&
              (response.statusCode == 400 || response.statusCode == 409)) {
            message = body['message'] as String;
          }
        } on Object {
          /* Keep the safe local error. */
        }
        throw AuthFailure(message);
      }
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please try again.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    } on FormatException {
      throw const AuthFailure(
        'The server returned an invalid response. Please retry.',
      );
    }
  }

  Future<List<ConnectionRow>> connections(
    String status,
    String direction,
    String name,
  ) async {
    final rows = <ConnectionRow>[];
    var page = 0;
    while (true) {
      final json = await _request(
        () async => _client.get(
          Uri(
            path: '/api/v1/connections',
            queryParameters: {
              'status': status,
              'direction': direction,
              'sort': 'NAME',
              'page': '$page',
              'size': '50',
              if (name.isNotEmpty) 'name': name,
            },
          ).toString(),
          headers: await _headers,
        ),
      );
      final items = _parse(
        () => (json['items'] as List<dynamic>)
            .map((item) => ConnectionRow.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      rows.addAll(items);
      if (items.isEmpty ||
          rows.length >=
              ((json['totalElements'] as num?)?.toInt() ?? rows.length)) {
        break;
      }
      page++;
    }
    return rows;
  }

  T _parse<T>(T Function() read) {
    try {
      return read();
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid response. Please retry.',
      );
    }
  }

  Future<MemberSearchPage> members(MemberFilters filters, int page) async {
    final json = await _request(
      () async => _client.get(
        Uri(
          path: '/api/v1/members',
          queryParameters: {...filters.query, 'page': '$page', 'size': '20'},
        ).toString(),
        headers: await _headers,
      ),
    );
    return _parse(() => MemberSearchPage.fromJson(json));
  }

  Future<MemberProfile> member(int id) async {
    final json = await _request(
      () async => _client.get('/api/v1/members/$id', headers: await _headers),
    );
    return _parse(() => MemberProfile.fromJson(json));
  }

  Future<Map<String, dynamic>> catalog() => _request(
    () async => _client.get(
      '/api/v1/profile/academic-options',
      headers: await _headers,
    ),
  );

  Future<void> act(int id, String action) async {
    await _request(
      () async => _client.post(
        '/api/v1/connections/$id/$action',
        headers: await _headers,
      ),
    );
  }

  Future<void> send(int receiverId, String intro) async {
    await _request(
      () async => _client.post(
        '/api/v1/connections',
        headers: await _headers,
        body: {
          'receiverId': receiverId,
          'introductoryMessage': intro.isEmpty ? null : intro,
        },
      ),
      accepted: const {201},
    );
  }
}
