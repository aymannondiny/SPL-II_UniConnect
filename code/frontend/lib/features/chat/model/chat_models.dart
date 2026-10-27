enum ChatSendState { sending, sent, failed }

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.otherUserId,
    required this.otherFullName,
    required this.canSend,
    required this.unreadCount,
    required this.lastMessageAt,
    required this.latestVisibleMessage,
  });

  final int id;
  final int otherUserId;
  final String otherFullName;
  final bool canSend;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final ChatMessage? latestVisibleMessage;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: (json['id'] as num).toInt(),
      otherUserId: (json['otherUserId'] as num).toInt(),
      otherFullName: json['otherFullName'] as String? ?? 'Former User',
      canSend: json['canSend'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessageAt: _date(json['lastMessageAt']),
      latestVisibleMessage: json['latestVisibleMessage'] == null
          ? null
          : ChatMessage.fromJson(
              json['latestVisibleMessage'] as Map<String, dynamic>,
            ),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.clientMessageId,
    required this.content,
    required this.sentAt,
    required this.deliveredAt,
    required this.readAt,
    required this.deletedForEveryoneAt,
    this.sendState = ChatSendState.sent,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String clientMessageId;
  final String? content;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? deletedForEveryoneAt;
  final ChatSendState sendState;

  bool get deletedForEveryone => deletedForEveryoneAt != null;
  bool get locallyPending => sendState != ChatSendState.sent;

  ChatMessage withSendState(ChatSendState state) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    clientMessageId: clientMessageId,
    content: content,
    sentAt: sentAt,
    deliveredAt: deliveredAt,
    readAt: readAt,
    deletedForEveryoneAt: deletedForEveryoneAt,
    sendState: state,
  );

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as num).toInt(),
      conversationId: (json['conversationId'] as num).toInt(),
      senderId: (json['senderId'] as num).toInt(),
      clientMessageId: json['clientMessageId'] as String? ?? '',
      content: json['content'] as String?,
      sentAt: _date(json['sentAt']) ?? DateTime.now(),
      deliveredAt: _date(json['deliveredAt']),
      readAt: _date(json['readAt']),
      deletedForEveryoneAt: _date(json['deletedForEveryoneAt']),
    );
  }
}

class ChatHistory {
  const ChatHistory({
    required this.conversationId,
    required this.canSend,
    required this.items,
    required this.hasMore,
    required this.nextBeforeMessageId,
  });

  final int conversationId;
  final bool canSend;
  final List<ChatMessage> items;
  final bool hasMore;
  final int? nextBeforeMessageId;

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      conversationId: (json['conversationId'] as num).toInt(),
      canSend: json['canSend'] as bool? ?? false,
      items: (json['items'] as List<dynamic>)
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      hasMore: json['hasMore'] as bool? ?? false,
      nextBeforeMessageId: (json['nextBeforeMessageId'] as num?)?.toInt(),
    );
  }
}

class ChatConnection {
  const ChatConnection({required this.userId, required this.fullName});

  final int userId;
  final String fullName;

  factory ChatConnection.fromJson(Map<String, dynamic> json) => ChatConnection(
    userId: (json['otherUserId'] as num).toInt(),
    fullName: json['fullName'] as String? ?? 'Unavailable member',
  );
}

DateTime? _date(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
