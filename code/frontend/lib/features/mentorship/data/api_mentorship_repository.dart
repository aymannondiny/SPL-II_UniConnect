import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/create_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile.dart';
import 'package:uniconnect/features/mentorship/model/mentor_registration_request.dart';
import 'package:uniconnect/features/mentorship/model/mentor_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_filter_params.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/model/update_slot_request.dart';

class ApiMentorshipRepository implements MentorshipRepository {
  ApiMentorshipRepository(this.client, this.session);

  final ApiClient client;
  final SessionController session;

  Future<Map<String, String>> get _headers async => {
    'Authorization': 'Bearer ${await session.accessToken()}',
    'Content-Type': 'application/json',
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
          400 => 'Please check the mentorship details and try again.',
          403 =>
            'Your account is not eligible to perform this mentorship action.',
          404 => 'The requested mentor profile or session slot was not found.',
          409 => 'The slot status changed or capacity is full. Please refresh.',
          _ => 'Unable to reach Mentorship service. Please retry.',
        };
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic> && body['message'] is String) {
            message = body['message'] as String;
          }
        } on Object {
          // Keep default message if response body is not JSON
        }
        throw AuthFailure(message);
      }
      return response;
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw const AuthFailure(
        'The mentorship request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    } on FormatException {
      throw const AuthFailure(
        'The server returned an invalid Mentorship response.',
      );
    }
  }

  Future<Map<String, dynamic>> _jsonMap(
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
        'The server returned an invalid Mentorship response.',
      );
    }
  }

  Future<List<dynamic>> _jsonList(
    Future<http.Response> Function() send, {
    required Set<int> accepted,
  }) async {
    final response = await _request(send, accepted: accepted);
    try {
      final body = jsonDecode(response.body);
      if (body is! List<dynamic>) throw const FormatException();
      return body;
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid Mentorship list response.',
      );
    }
  }

  @override
  Future<MentorshipPageResult<MentorSummary>> browseMentors(
    MentorFilterParams params,
  ) async {
    final uri = Uri(
      path: '/api/v1/mentorship/mentors',
      queryParameters: params.toQueryParameters(),
    );
    final json = await _jsonMap(
      () async => client.get(uri.toString(), headers: await _headers),
      accepted: const {200},
    );
    return MentorshipPageResult<MentorSummary>.fromJson(
      json,
      MentorSummary.fromJson,
    );
  }

  @override
  Future<MentorProfile> getMentorProfile(int mentorProfileId) async {
    final json = await _jsonMap(
      () async => client.get(
        '/api/v1/mentorship/mentors/$mentorProfileId',
        headers: await _headers,
      ),
      accepted: const {200},
    );
    return MentorProfile.fromJson(json);
  }

  @override
  Future<MentorProfile> getMyMentorProfile() async {
    final json = await _jsonMap(
      () async =>
          client.get('/api/v1/mentorship/mentors/me', headers: await _headers),
      accepted: const {200},
    );
    return MentorProfile.fromJson(json);
  }

  @override
  Future<MentorProfile> registerAsMentor(
    MentorRegistrationRequest request,
  ) async {
    final json = await _jsonMap(
      () async => client.post(
        '/api/v1/mentorship/mentors',
        headers: await _headers,
        body: jsonEncode(request.toJson()),
      ),
      accepted: const {200, 201},
    );
    return MentorProfile.fromJson(json);
  }

  @override
  Future<MentorProfile> updateMentorStatus(MentorStatus status) async {
    final json = await _jsonMap(
      () async => client.patch(
        '/api/v1/mentorship/mentors/me/status',
        headers: await _headers,
        body: jsonEncode({'status': status.toApi()}),
      ),
      accepted: const {200},
    );
    return MentorProfile.fromJson(json);
  }

  @override
  Future<MentorshipPageResult<MentorshipSlotSummary>> browseSlots(
    SlotFilterParams params,
  ) async {
    final uri = Uri(
      path: '/api/v1/mentorship/slots',
      queryParameters: params.toQueryParameters(),
    );
    final json = await _jsonMap(
      () async => client.get(uri.toString(), headers: await _headers),
      accepted: const {200},
    );
    return MentorshipPageResult<MentorshipSlotSummary>.fromJson(
      json,
      MentorshipSlotSummary.fromJson,
    );
  }

  @override
  Future<MentorshipSlot> getSlotDetails(int slotId) async {
    final json = await _jsonMap(
      () async => client.get(
        '/api/v1/mentorship/slots/$slotId',
        headers: await _headers,
      ),
      accepted: const {200},
    );
    return MentorshipSlot.fromJson(json);
  }

  @override
  Future<MentorshipSlot> createSlot(CreateSlotRequest request) async {
    final json = await _jsonMap(
      () async => client.post(
        '/api/v1/mentorship/slots',
        headers: await _headers,
        body: jsonEncode(request.toJson()),
      ),
      accepted: const {200, 201},
    );
    return MentorshipSlot.fromJson(json);
  }

  @override
  Future<MentorshipSlot> updateSlot(
    int slotId,
    UpdateSlotRequest request,
  ) async {
    final json = await _jsonMap(
      () async => client.put(
        '/api/v1/mentorship/slots/$slotId',
        headers: await _headers,
        body: jsonEncode(request.toJson()),
      ),
      accepted: const {200},
    );
    return MentorshipSlot.fromJson(json);
  }

  @override
  Future<MentorshipEnrollment> joinSlot(
    int slotId,
    EnrollSlotRequest request,
  ) async {
    final json = await _jsonMap(
      () async => client.post(
        '/api/v1/mentorship/slots/$slotId/join',
        headers: await _headers,
        body: jsonEncode(request.toJson()),
      ),
      accepted: const {200},
    );
    return MentorshipEnrollment.fromJson(json);
  }

  @override
  Future<MentorshipEnrollment> leaveSlot(int slotId) async {
    final json = await _jsonMap(
      () async => client.post(
        '/api/v1/mentorship/slots/$slotId/leave',
        headers: await _headers,
        body: '',
      ),
      accepted: const {200},
    );
    return MentorshipEnrollment.fromJson(json);
  }

  @override
  Future<MentorshipSlot> closeSlot(int slotId) async {
    final json = await _jsonMap(
      () async => client.post(
        '/api/v1/mentorship/slots/$slotId/close',
        headers: await _headers,
        body: '',
      ),
      accepted: const {200},
    );
    return MentorshipSlot.fromJson(json);
  }

  @override
  Future<MentorshipSlot> cancelSlot(int slotId) async {
    final json = await _jsonMap(
      () async => client.post(
        '/api/v1/mentorship/slots/$slotId/cancel',
        headers: await _headers,
        body: '',
      ),
      accepted: const {200},
    );
    return MentorshipSlot.fromJson(json);
  }

  @override
  Future<List<MentorshipSlotSummary>> getMyMentoringSlots() async {
    final list = await _jsonList(
      () async => client.get(
        '/api/v1/mentorship/slots/my-mentoring',
        headers: await _headers,
      ),
      accepted: const {200},
    );
    return list
        .map((e) => MentorshipSlotSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MentorshipSlotSummary>> getMyEnrolledSlots() async {
    final list = await _jsonList(
      () async => client.get(
        '/api/v1/mentorship/slots/my-current-series',
        headers: await _headers,
      ),
      accepted: const {200},
    );
    return list
        .map((e) => MentorshipSlotSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MentorshipEnrollment>> getSlotAttendees(int slotId) async {
    final list = await _jsonList(
      () async => client.get(
        '/api/v1/mentorship/slots/$slotId/enrollments',
        headers: await _headers,
      ),
      accepted: const {200},
    );
    return list
        .map((e) => MentorshipEnrollment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
