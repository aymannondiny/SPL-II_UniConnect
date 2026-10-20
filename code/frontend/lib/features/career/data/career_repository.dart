import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/career/model/career_models.dart';

abstract interface class CareerRepository {
  Future<CareerPage<CareerPost>> browse({
    required int page,
    CareerEmploymentType? employmentType,
    CareerWorkMode? workMode,
    String? location,
    String? skill,
    required CareerSort sort,
  });

  Future<CareerPage<CareerPost>> mine({required int page});
  Future<CareerPage<SavedCareerPost>> saved({required int page});
  Future<CareerPost> detail(int postId);
  Future<CareerPost> create(CareerPostInput input);
  Future<CareerPost> update(int postId, CareerPostInput input);
  Future<CareerPost> close(int postId);
  Future<SavedCareerPost> save(int postId, {String? note});
  Future<void> unsave(int postId);
  Future<SavedCareerPost> updateNote(int savedJobId, String? note);
}

class ApiCareerRepository implements CareerRepository {
  ApiCareerRepository(this.client, this.session);

  final ApiClient client;
  final SessionController session;

  Future<Map<String, String>> get _headers async => {
    'Authorization': 'Bearer ${await session.accessToken()}',
  };

  Future<http.Response> _request(
    Future<http.Response> Function() send, {
    required Set<int> accepted,
  }) async {
    try {
      final response = await send().timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        session.expire();
        throw const AuthFailure(
          'Your session has ended. Please log in again.',
          sessionEnded: true,
        );
      }
      if (!accepted.contains(response.statusCode)) {
        String message = switch (response.statusCode) {
          400 => 'Please check the career post details and try again.',
          403 => 'Your account role cannot perform this Career Board action.',
          404 => 'That career post or saved item is no longer available.',
          409 => 'That career post changed. Refresh the board and try again.',
          _ => 'Unable to reach Career Board. Please retry.',
        };
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['message'] is String &&
              (response.statusCode == 400 || response.statusCode == 409)) {
            message = body['message'] as String;
          }
        } on Object {
          // Keep the safe local message when the server body is not JSON.
        }
        throw AuthFailure(message);
      }
      return response;
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
        'The server returned an invalid Career Board response.',
      );
    }
  }

  Future<Map<String, dynamic>> _json(
    Future<http.Response> Function() send, {
    required Set<int> accepted,
  }) async {
    final response = await _request(send, accepted: accepted);
    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) throw const FormatException();
      return body;
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid Career Board response.',
      );
    }
  }

  @override
  Future<CareerPage<CareerPost>> browse({
    required int page,
    CareerEmploymentType? employmentType,
    CareerWorkMode? workMode,
    String? location,
    String? skill,
    required CareerSort sort,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'size': '20',
      'sort': sort == CareerSort.deadline ? 'DEADLINE_ASC' : 'POSTED_AT_DESC',
      if (employmentType != null) 'employmentType': employmentType.apiValue,
      if (workMode != null) 'workMode': workMode.apiValue,
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
      if (skill != null && skill.trim().isNotEmpty) 'skill': skill.trim(),
    };
    final json = await _json(
      () async => client.get(
        Uri(path: '/api/v1/career/posts', queryParameters: query).toString(),
        headers: await _headers,
      ),
      accepted: const {200},
    );
    return CareerPage<CareerPost>.fromJson(json, CareerPost.fromJson);
  }

  @override
  Future<CareerPage<CareerPost>> mine({required int page}) async {
    final json = await _json(
      () async => client.get(
        '/api/v1/career/posts/mine?page=$page&size=20',
        headers: await _headers,
      ),
      accepted: const {200},
    );
    return CareerPage<CareerPost>.fromJson(json, CareerPost.fromJson);
  }

  @override
  Future<CareerPage<SavedCareerPost>> saved({required int page}) async {
    final json = await _json(
      () async => client.get(
        '/api/v1/career/saved?page=$page&size=20',
        headers: await _headers,
      ),
      accepted: const {200},
    );
    return CareerPage<SavedCareerPost>.fromJson(json, SavedCareerPost.fromJson);
  }

  @override
  Future<CareerPost> detail(int postId) async => CareerPost.fromJson(
    await _json(
      () async =>
          client.get('/api/v1/career/posts/$postId', headers: await _headers),
      accepted: const {200},
    ),
  );

  @override
  Future<CareerPost> create(CareerPostInput input) async => CareerPost.fromJson(
    await _json(
      () async => client.post(
        '/api/v1/career/posts',
        headers: await _headers,
        body: input.toJson(),
      ),
      accepted: const {201},
    ),
  );

  @override
  Future<CareerPost> update(int postId, CareerPostInput input) async =>
      CareerPost.fromJson(
        await _json(
          () async => client.put(
            '/api/v1/career/posts/$postId',
            headers: await _headers,
            body: input.toJson(),
          ),
          accepted: const {200},
        ),
      );

  @override
  Future<CareerPost> close(int postId) async => CareerPost.fromJson(
    await _json(
      () async => client.post(
        '/api/v1/career/posts/$postId/close',
        headers: await _headers,
      ),
      accepted: const {200},
    ),
  );

  @override
  Future<SavedCareerPost> save(int postId, {String? note}) async =>
      SavedCareerPost.fromJson(
        await _json(
          () async => client.post(
            '/api/v1/career/posts/$postId/save',
            headers: await _headers,
            body: {'note': _clean(note)},
          ),
          accepted: const {201},
        ),
      );

  @override
  Future<void> unsave(int postId) async {
    await _request(
      () async => client.delete(
        '/api/v1/career/posts/$postId/save',
        headers: await _headers,
      ),
      accepted: const {204},
    );
  }

  @override
  Future<SavedCareerPost> updateNote(int savedJobId, String? note) async =>
      SavedCareerPost.fromJson(
        await _json(
          () async => client.patch(
            '/api/v1/career/saved/$savedJobId',
            headers: await _headers,
            body: {'note': _clean(note)},
          ),
          accepted: const {200},
        ),
      );

  String? _clean(String? value) {
    final note = value?.trim();
    return note == null || note.isEmpty ? null : note;
  }
}
