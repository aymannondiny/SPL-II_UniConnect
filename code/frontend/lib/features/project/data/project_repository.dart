import 'dart:async';
import 'dart:convert';

import 'package:uniconnect/core/network/response_parser.dart';
import 'package:uniconnect/core/network/paged_loader.dart';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/project/model/project_models.dart';

class ProjectRepository {
  ProjectRepository(this._client, this.session);

  final ApiClient _client;
  final SessionController session;

  Future<Map<String, String>> get _headers async => {
    'Authorization': 'Bearer ${await session.accessToken()}',
  };

  Future<http.Response> _request(
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
        var message = switch (response.statusCode) {
          400 => 'Please check the project details and try again.',
          403 => 'Project Finder is available to active student accounts.',
          404 => 'That project or application is no longer available.',
          409 => 'This project changed while you were working. Refresh and try again.',
          _ => 'Unable to reach Project Finder. Please retry.',
        };
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          if (json['message'] is String &&
              (response.statusCode == 400 || response.statusCode == 409)) {
            message = json['message'] as String;
          }
        } on Object {
          // Keep the safe local error message when the response is not JSON.
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
    }
  }

  Map<String, dynamic> _jsonMap(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      if (value is! Map<String, dynamic>) throw const FormatException();
      return value;
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid project response. Please retry.',
      );
    }
  }

  List<dynamic> _jsonList(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      if (value is! List<dynamic>) throw const FormatException();
      return value;
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid project response. Please retry.',
      );
    }
  }

  Future<ProjectPage<ProjectListing>> browse(
    ProjectBrowseFilters filters,
    int page,
  ) async {
    final query = {...filters.query, 'page': '$page', 'size': '20'};
    final response = await _request(
      () async => _client.get(
        Uri(path: '/api/v1/projects', queryParameters: query).toString(),
        headers: await _headers,
      ),
    );
    return parseResponse(
      () => ProjectPage<ProjectListing>.fromJson(
        _jsonMap(response),
        ProjectListing.fromJson,
      ),
      resource: 'project',
    );
  }

  Future<ProjectPage<ProjectListing>> mine(int page) async {
    final response = await _request(
      () async => _client.get(
        Uri(
          path: '/api/v1/projects/mine',
          queryParameters: {'page': '$page', 'size': '20'},
        ).toString(),
        headers: await _headers,
      ),
    );
    return parseResponse(
      () => ProjectPage<ProjectListing>.fromJson(
        _jsonMap(response),
        ProjectListing.fromJson,
      ),
      resource: 'project',
    );
  }

  Future<ProjectPage<AppliedProject>> applied(int page) async {
    final response = await _request(
      () async => _client.get(
        Uri(
          path: '/api/v1/projects/applied',
          queryParameters: {'page': '$page', 'size': '20'},
        ).toString(),
        headers: await _headers,
      ),
    );
    return parseResponse(
      () => ProjectPage<AppliedProject>.fromJson(
        _jsonMap(response),
        AppliedProject.fromJson,
      ),
      resource: 'project',
    );
  }

  Future<ProjectPage<ProjectCandidate>> candidates({
    required List<String> requiredSkills,
    List<String> optionalSkills = const [],
    int? departmentId,
    int? yearOfStudy,
    bool? projectAvailable,
    String sort = 'NAME_ASC',
    int page = 0,
  }) async {
    final query = <String, dynamic>{
      'requiredSkills': requiredSkills,
      'page': '$page',
      'size': '20',
      'sort': sort,
    };
    if (optionalSkills.isNotEmpty) query['optionalSkills'] = optionalSkills;
    if (departmentId != null) query['departmentId'] = '$departmentId';
    if (yearOfStudy != null) query['yearOfStudy'] = '$yearOfStudy';
    if (projectAvailable != null) {
      query['projectAvailable'] = '$projectAvailable';
    }
    final response = await _request(
      () async => _client.get(
        Uri(
          path: '/api/v1/projects/candidates',
          queryParameters: query,
        ).toString(),
        headers: await _headers,
      ),
    );
    return parseResponse(
      () => ProjectPage<ProjectCandidate>.fromJson(
        _jsonMap(response),
        ProjectCandidate.fromJson,
      ),
      resource: 'project',
    );
  }

  Future<ProjectPage<ProjectCandidate>> projectCandidates(
    int projectId, {
    int? departmentId,
    int? yearOfStudy,
    bool? projectAvailable,
    String sort = 'NAME_ASC',
    int page = 0,
  }) async {
    final query = <String, String>{'page': '$page', 'size': '20', 'sort': sort};
    if (departmentId != null) query['departmentId'] = '$departmentId';
    if (yearOfStudy != null) query['yearOfStudy'] = '$yearOfStudy';
    if (projectAvailable != null) {
      query['projectAvailable'] = '$projectAvailable';
    }
    final response = await _request(
      () async => _client.get(
        Uri(
          path: '/api/v1/projects/$projectId/candidates',
          queryParameters: query,
        ).toString(),
        headers: await _headers,
      ),
    );
    return parseResponse(
      () => ProjectPage<ProjectCandidate>.fromJson(
        _jsonMap(response),
        ProjectCandidate.fromJson,
      ),
      resource: 'project candidate',
    );
  }

  Future<List<ProjectDepartment>> departments() async {
    final response = await _request(
      () async => _client.get(
        '/api/v1/profile/academic-options',
        headers: await _headers,
      ),
    );
    final json = _jsonMap(response);
    try {
      return (json['departments'] as List<dynamic>? ?? const [])
          .map(
            (item) => ProjectDepartment.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on Object {
      throw const AuthFailure(
        'The server returned invalid department options. Please retry.',
      );
    }
  }

  Future<ProjectListing> detail(int projectId) async {
    final response = await _request(
      () async =>
          _client.get('/api/v1/projects/$projectId', headers: await _headers),
    );
    return parseResponse(
      () => ProjectListing.fromJson(_jsonMap(response)),
      resource: 'project',
    );
  }

  Future<ProjectListing> create(ProjectRequestData request) async {
    final response = await _request(
      () async => _client.post(
        '/api/v1/projects',
        headers: await _headers,
        body: request.toJson(),
      ),
      accepted: const {201},
    );
    return parseResponse(
      () => ProjectListing.fromJson(_jsonMap(response)),
      resource: 'project',
    );
  }

  Future<ProjectListing> update(
    int projectId,
    ProjectRequestData request,
  ) async {
    final response = await _request(
      () async => _client.put(
        '/api/v1/projects/$projectId',
        headers: await _headers,
        body: request.toJson(),
      ),
    );
    return parseResponse(
      () => ProjectListing.fromJson(_jsonMap(response)),
      resource: 'project',
    );
  }

  Future<ProjectListing> _projectAction(int projectId, String action) async {
    final response = await _request(
      () async => _client.post(
        '/api/v1/projects/$projectId/$action',
        headers: await _headers,
      ),
    );
    return parseResponse(
      () => ProjectListing.fromJson(_jsonMap(response)),
      resource: 'project',
    );
  }

  Future<ProjectListing> close(int projectId) =>
      _projectAction(projectId, 'close');
  Future<ProjectListing> reopen(int projectId) =>
      _projectAction(projectId, 'reopen');

  Future<void> delete(int projectId) async {
    await _request(
      () async => _client.delete(
        '/api/v1/projects/$projectId',
        headers: await _headers,
        body: const {'confirmed': true},
      ),
      accepted: const {204},
    );
  }

  Future<ProjectApplication> apply(int projectId, String message) async {
    final response = await _request(
      () async => _client.post(
        '/api/v1/projects/$projectId/applications',
        headers: await _headers,
        body: message.trim().isEmpty ? null : {'message': message.trim()},
      ),
      accepted: const {201},
    );
    return parseResponse(
      () => ProjectApplication.fromJson(_jsonMap(response)),
      resource: 'project',
    );
  }

  Future<ProjectPage<ProjectApplication>> applications(int projectId) async {
    final items = await loadAllPages<ProjectApplication>((page) async {
      final response = await _request(
        () async => _client.get(
          '/api/v1/projects/$projectId/applications?page=$page&size=50',
          headers: await _headers,
        ),
      );
      final result = parseResponse(
        () => ProjectPage<ProjectApplication>.fromJson(
          _jsonMap(response),
          ProjectApplication.fromJson,
        ),
        resource: 'project applications',
      );
      return (items: result.items, total: result.totalElements);
    });
    return ProjectPage(
      items: items,
      page: 0,
      size: items.length,
      totalElements: items.length,
    );
  }

  Future<ProjectApplication> review(int applicationId, String decision) async {
    final response = await _request(
      () async => _client.post(
        '/api/v1/projects/applications/$applicationId/$decision',
        headers: await _headers,
      ),
    );
    return parseResponse(
      () => ProjectApplication.fromJson(_jsonMap(response)),
      resource: 'project',
    );
  }

  Future<List<ProjectMember>> members(int projectId) async {
    final response = await _request(
      () async => _client.get(
        '/api/v1/projects/$projectId/members',
        headers: await _headers,
      ),
    );
    try {
      return _jsonList(response)
          .map((item) => ProjectMember.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AuthFailure {
      rethrow;
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid team list. Please retry.',
      );
    }
  }

  Future<List<ProjectRecommendation>> recommendations(int projectId) async {
    final response = await _request(
      () async => _client.get(
        '/api/v1/projects/$projectId/recommendations',
        headers: await _headers,
      ),
    );
    try {
      return _jsonList(response)
          .map(
            (item) =>
                ProjectRecommendation.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on AuthFailure {
      rethrow;
    } on Object {
      throw const AuthFailure(
        'The server returned invalid teammate recommendations. Please retry.',
      );
    }
  }

  Future<ProjectPage<ProjectAuditEntry>> audit(int projectId) async {
    final items = await loadAllPages<ProjectAuditEntry>((page) async {
      final response = await _request(
        () async => _client.get(
          '/api/v1/projects/$projectId/audit?page=$page&size=50',
          headers: await _headers,
        ),
      );
      final result = parseResponse(
        () => ProjectPage<ProjectAuditEntry>.fromJson(
          _jsonMap(response),
          ProjectAuditEntry.fromJson,
        ),
        resource: 'project audit',
      );
      return (items: result.items, total: result.totalElements);
    });
    return ProjectPage(
      items: items,
      page: 0,
      size: items.length,
      totalElements: items.length,
    );
  }
}
