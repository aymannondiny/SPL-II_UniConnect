import 'dart:async';
import 'dart:convert';

import 'package:uniconnect/core/config/app_config.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';

import 'chat_socket.dart';

class ChatFailure implements Exception {
  const ChatFailure(this.message, {this.sessionEnded = false});
  final String message;
  final bool sessionEnded;

  @override
  String toString() => message;
}

class ChatRepository {
  ChatRepository(this._client);
  final ApiClient _client;

  Future<ChatSocketConnection> connect(String token) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final socketUri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/chat',
      query: null,
      fragment: null,
    );
    return connectChatSocket(socketUri, token);
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };

  Future<List<ChatConversation>> conversations(String token) async {
    final rows = await _allPages('/api/v1/chat/conversations', token);
    return rows.map(ChatConversation.fromJson).toList(growable: false);
  }

  Future<ChatHistory> history(
    String token,
    int conversationId, {
    int? beforeMessageId,
  }) async {
    final query = <String, String>{'size': '20'};
    if (beforeMessageId != null) {
      query['beforeMessageId'] = '$beforeMessageId';
    }
    final path = Uri(
      path: '/api/v1/chat/conversations/$conversationId/messages',
      queryParameters: query,
    ).toString();
    return ChatHistory.fromJson(
      await _request(() => _client.get(path, headers: _headers(token))),
    );
  }

  Future<List<ChatConnection>> acceptedConnections(String token) async {
    final rows = await _allPages(
      '/api/v1/connections',
      token,
      parameters: {'status': 'ACCEPTED', 'direction': 'ALL', 'sort': 'NAME'},
    );
    return rows.map(ChatConnection.fromJson).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _allPages(
    String path,
    String token, {
    Map<String, String> parameters = const {},
  }) async {
    final rows = <Map<String, dynamic>>[];
    var page = 0;
    while (true) {
      final json = await _request(
        () => _client.get(
          Uri(
            path: path,
            queryParameters: {...parameters, 'page': '$page', 'size': '50'},
          ).toString(),
          headers: _headers(token),
        ),
      );
      final items = (json['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
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

  Future<ChatMessage> send(
    String token, {
    required int receiverId,
    required String clientMessageId,
    required String content,
  }) async {
    final json = await _request(
      () => _client.post(
        '/api/v1/chat/messages',
        body: {
          'receiverId': receiverId,
          'clientMessageId': clientMessageId,
          'content': content,
        },
        headers: _headers(token),
      ),
    );
    return ChatMessage.fromJson(json);
  }

  Future<ChatMessage> acknowledgeDelivered(String token, int messageId) async {
    final json = await _request(
      () => _client.patch(
        '/api/v1/chat/messages/$messageId/delivered',
        headers: _headers(token),
      ),
    );
    return ChatMessage.fromJson(json);
  }

  Future<void> deleteConversation(String token, int conversationId) async {
    await _request(
      () => _client.delete(
        '/api/v1/chat/conversations/$conversationId/self',
        headers: _headers(token),
      ),
      expectedStatus: 204,
    );
  }

  Future<void> deleteMessage(
    String token,
    int messageId, {
    required bool forEveryone,
  }) async {
    final scope = forEveryone ? 'everyone' : 'self';
    await _request(
      () => _client.delete(
        '/api/v1/chat/messages/$messageId/$scope',
        headers: _headers(token),
      ),
      expectedStatus: 204,
    );
  }

  Future<Map<String, dynamic>> _request(
    Future<dynamic> Function() send, {
    int expectedStatus = 200,
  }) async {
    try {
      final response = await send().timeout(const Duration(seconds: 20));
      if (response.statusCode != expectedStatus) {
        throw _failure(response.statusCode, response.body);
      }
      if (expectedStatus == 204 || response.body.isEmpty) {
        return <String, dynamic>{};
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on ChatFailure {
      rethrow;
    } on TimeoutException {
      throw const ChatFailure('The request timed out. Please try again.');
    } on FormatException {
      throw const ChatFailure('The server returned an invalid chat response.');
    } on Object {
      throw const ChatFailure(
        'Cannot reach UniConnect. Check your connection and try again.',
      );
    }
  }

  ChatFailure _failure(int status, String body) {
    String? code;
    try {
      code = (jsonDecode(body) as Map<String, dynamic>)['code'] as String?;
    } on Object {
      // Use a safe local fallback for non-JSON proxy responses.
    }
    if (status == 401 ||
        code == 'INVALID_SESSION' ||
        code == 'AUTHENTICATION_REQUIRED') {
      return const ChatFailure(
        'Your session has ended. Please log in again.',
        sessionEnded: true,
      );
    }
    if (status == 403) {
      return const ChatFailure(
        'You can no longer send messages to this connection.',
      );
    }
    if (status == 404) {
      return const ChatFailure('This conversation is no longer available.');
    }
    return ChatFailure(
      status == 409
          ? 'That message could not be retried. Please write it again.'
          : 'Unable to complete the chat request. Please try again.',
    );
  }
}
