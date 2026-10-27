part of '../chat_page.dart';

extension _ChatMutations on _ChatPageState {
  Future<void> _sendMessage() async {
    final connection = _draftConnection;
    final conversation = _selected;
    final recipientId = connection?.userId ?? conversation?.otherUserId;
    final text = _composer.text;
    final token = _token;
    if (recipientId == null || token == null) return;
    if (text.trim().isEmpty) return;
    if (text.length > 5000) {
      _showError('Messages can contain at most 5,000 characters.');
      return;
    }
    final messageId = _uuidV4();
    final timing = Stopwatch()..start();
    final recipientName =
        connection?.fullName ?? conversation?.otherFullName ?? 'Connection';
    final pending = ChatMessage(
      id: _nextPendingMessageId--,
      conversationId: conversation?.id ?? 0,
      senderId: _myUserId!,
      clientMessageId: messageId,
      content: text,
      sentAt: DateTime.now().toUtc(),
      deliveredAt: null,
      readAt: null,
      deletedForEveryoneAt: null,
      sendState: ChatSendState.sending,
    );
    _composer.clear();
    _update(() {
      _sendingMessageIds.add(messageId);
      _pendingSendTargets[messageId] = _PendingSendTarget(
        recipientId: recipientId,
        fullName: recipientName,
      );
      _localOutbox.putIfAbsent(recipientId, () => []).add(pending);
      _upsertVisibleMessage(pending);
      _showThread = true;
    });
    _logSendTiming(messageId, 'local-ui', timing);
    _scrollToLatest();
    await _persistPendingMessage(pending, timing: timing);
  }

  Future<void> _retryMessage(ChatMessage message) async {
    if (message.sendState != ChatSendState.failed ||
        _sendingMessageIds.contains(message.clientMessageId)) {
      return;
    }
    final sending = message.withSendState(ChatSendState.sending);
    _update(() {
      _sendingMessageIds.add(message.clientMessageId);
      _replaceLocalMessage(sending);
    });
    await _persistPendingMessage(sending, timing: Stopwatch()..start());
  }

  Future<void> _persistPendingMessage(
    ChatMessage pending, {
    required Stopwatch timing,
  }) async {
    final target = _pendingSendTargets[pending.clientMessageId];
    final token = _token;
    if (target == null || token == null || pending.content == null) return;
    try {
      final sent = await _repository.send(
        token,
        receiverId: target.recipientId,
        clientMessageId: pending.clientMessageId,
        content: pending.content!,
      );
      _logSendTiming(pending.clientMessageId, 'server-ack', timing);
      if (!mounted) return;
      _update(() {
        _removeLocalMessage(pending.clientMessageId);
        final targetIsVisible =
            _selected?.otherUserId == target.recipientId ||
            _draftConnection?.userId == target.recipientId;
        if (targetIsVisible) {
          _upsertVisibleMessage(sent);
          _selected = ChatConversation(
            id: sent.conversationId,
            otherUserId: target.recipientId,
            otherFullName: target.fullName,
            canSend: true,
            unreadCount: 0,
            lastMessageAt: sent.sentAt,
            latestVisibleMessage: sent,
          );
          _draftConnection = null;
          _showThread = true;
        }
        final updatedConversation = ChatConversation(
          id: sent.conversationId,
          otherUserId: target.recipientId,
          otherFullName: target.fullName,
          canSend: true,
          unreadCount: 0,
          lastMessageAt: sent.sentAt,
          latestVisibleMessage: sent,
        );
        _conversations = [
          updatedConversation,
          ..._conversations.where(
            (conversation) => conversation.id != sent.conversationId,
          ),
        ];
      });
      _scrollToLatest();
    } on ChatFailure catch (failure) {
      _logSendTiming(pending.clientMessageId, 'failed', timing);
      if (mounted) {
        _update(() {
          _sendingMessageIds.remove(pending.clientMessageId);
          final stillLocal = _localOutbox.values.any(
            (messages) => messages.any(
              (message) => message.clientMessageId == pending.clientMessageId,
            ),
          );
          if (stillLocal) {
            _replaceLocalMessage(pending.withSendState(ChatSendState.failed));
          }
        });
        _showError(failure.message);
      }
      if (failure.sessionEnded) _expireSession();
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
