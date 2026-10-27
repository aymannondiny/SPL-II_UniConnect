import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/data/chat_socket_contract.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';

/// Deterministic messaging fixture for visual and navigation regression tests.
class FakeChatRepository extends ChatRepository {
  FakeChatRepository(super.client);
  int? openedConversation;
  int? sentRecipient;
  bool connected = true;
  bool conversationDeleted = false;
  @override
  Future<void> deleteConversation(String token, int conversationId) async {
    conversationDeleted = true;
    sent.clear();
  }

  final List<ChatMessage> sent = [];
  @override
  Future<ChatSocketConnection> connect(String token) async => _QuietSocket();
  @override
  Future<List<ChatConversation>> conversations(String token) async =>
      conversationDeleted
      ? []
      : [
          ChatConversation(
            id: 81,
            otherUserId: 2,
            otherFullName: 'Nafisa Rahman',
            canSend: true,
            unreadCount: 0,
            lastMessageAt: null,
            latestVisibleMessage: null,
          ),
        ];
  @override
  Future<List<ChatConnection>> acceptedConnections(String token) async =>
      connected
      ? [
          const ChatConnection(userId: 2, fullName: 'Nafisa Rahman'),
          const ChatConnection(userId: 5, fullName: 'Community Member 5'),
        ]
      : [];
  @override
  Future<ChatHistory> history(
    String token,
    int conversationId, {
    int? beforeMessageId,
  }) async {
    openedConversation = conversationId;
    return ChatHistory(
      conversationId: conversationId,
      canSend: true,
      items: sent,
      hasMore: false,
      nextBeforeMessageId: null,
    );
  }

  @override
  Future<ChatMessage> send(
    String token, {
    required int receiverId,
    required String clientMessageId,
    required String content,
  }) async {
    sentRecipient = receiverId;
    conversationDeleted = false;
    final message = ChatMessage(
      id: sent.length + 1,
      conversationId: 81,
      senderId: 1,
      clientMessageId: clientMessageId,
      content: content,
      sentAt: DateTime.now(),
      deliveredAt: null,
      readAt: null,
      deletedForEveryoneAt: null,
    );
    sent.add(message);
    return message;
  }
}

class _QuietSocket implements ChatSocketConnection {
  @override
  Stream<String> get messages => const Stream.empty();
  @override
  void send(String message) {}
  @override
  Future<void> close() async {}
}
