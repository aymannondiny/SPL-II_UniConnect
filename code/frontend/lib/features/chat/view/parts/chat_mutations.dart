part of '../chat_page.dart';

extension _ChatMutations on _ChatPageState {
  Future<void> _sendMessage() async {
    final connection = _draftConnection;
    final conversation = _selected;
    final recipientId = connection?.userId ?? conversation?.otherUserId;
    final text = _composer.text;
    final token = _token;
    if (recipientId == null || token == null || _sending) return;
    if (_deletingConversations.contains(conversation?.id)) return;
    if (text.trim().isEmpty) return;
    if (text.length > 5000) {
      _showError('Messages can contain at most 5,000 characters.');
      return;
    }
    final messageId =
        _retryContent == text &&
            _retryRecipientId == recipientId &&
            _retryMessageId != null
        ? _retryMessageId!
        : _uuidV4();
    _update(() {
      _sending = true;
      _retryMessageId = messageId;
      _retryContent = text;
      _retryRecipientId = recipientId;
    });
    try {
      final sent = await _repository.send(
        token,
        receiverId: recipientId,
        clientMessageId: messageId,
        content: text,
      );
      if (!mounted) return;
      _composer.clear();
      _update(() {
        _retryMessageId = null;
        _retryContent = null;
        _retryRecipientId = null;
        _selected = ChatConversation(
          id: sent.conversationId,
          otherUserId: recipientId,
          otherFullName: connection?.fullName ?? conversation!.otherFullName,
          canSend: true,
          unreadCount: 0,
          lastMessageAt: sent.sentAt,
          latestVisibleMessage: sent,
        );
        _draftConnection = null;
        _messages.add(sent);
        _showThread = true;
      });
      await _refreshInbox(quiet: true);
      final current = _conversations.where(
        (item) => item.id == sent.conversationId,
      );
      if (current.isNotEmpty && mounted) {
        _update(() => _selected = current.first);
      }
      _scrollToLatest();
    } on ChatFailure catch (failure) {
      if (mounted) _showError(failure.message);
      if (failure.sessionEnded) _expireSession();
    } finally {
      if (mounted) _update(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(ChatMessage message, bool forEveryone) async {
    final token = _token;
    if (token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(forEveryone ? 'Delete for everyone?' : 'Delete for you?'),
        content: Text(
          forEveryone
              ? 'The message content will be removed from both participants’ histories.'
              : 'This message will be hidden from your own history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteMessage(
        token,
        message.id,
        forEveryone: forEveryone,
      );
      if (!forEveryone && mounted) {
        _update(() => _messages.removeWhere((item) => item.id == message.id));
      }
      final selected = _selected;
      if (selected != null) await _loadHistory(selected, quiet: true);
      await _refreshInbox(quiet: true);
    } on ChatFailure catch (failure) {
      _showError(failure.message);
      if (failure.sessionEnded) _expireSession();
    }
  }
}
