import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/notification/model/app_notification.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> list();
  Future<void> markRead(int id);
  Future<void> markAllRead();
}

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this.client, this.session);
  final ApiClient client;
  final SessionController session;
  static const _pageSize = 50;

  Future<http.Response> _request(String method, String path, {int? id}) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${await session.accessToken()}',
      };
      final response = switch (method) {
        'PATCH' => client.patch(path, headers: headers),
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
      final expected = method == 'PATCH' && path.endsWith('/read') && id != null
          ? 200
          : method == 'PATCH'
          ? 204
          : 200;
      if (result.statusCode != expected) {
        throw AuthFailure(switch (result.statusCode) {
          403 => 'Your account cannot access these notifications.',
          _ =>
            'The notification service returned HTTP ${result.statusCode}. Please retry.',
        });
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

  @override
  Future<List<AppNotification>> list() async {
    final response = await _request(
      'GET',
      '/api/v1/notifications?page=0&size=$_pageSize',
    );
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return [
        for (final item in json['items'] as List)
          AppNotification.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      throw const AuthFailure(
        'The server returned an invalid notifications response.',
      );
    }
  }

  @override
  Future<void> markRead(int id) async {
    await _request('PATCH', '/api/v1/notifications/$id/read', id: id);
  }

  @override
  Future<void> markAllRead() async {
    await _request('PATCH', '/api/v1/notifications/read');
  }
}
