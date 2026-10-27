part of '../chat_page.dart';

extension _ChatDeletion on _ChatPageState {
  Future<void> _deleteConversation(ChatConversation conversation) async {
    final token = _token;
    if (token == null ||
        _hasActiveSendTo(conversation.otherUserId) ||
        !_deletingConversations.add(conversation.id)) {
      return;
    }
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          constraints: const BoxConstraints(maxWidth: 480),
          title: const Text('Delete chat for me?'),
          content: Text(
            'Remove your chat with ${conversation.otherFullName} and its existing '
            'messages from your history? The other person keeps their copy. '
            'A new message will bring this chat back. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete chat'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _update(() {});
      await _repository.deleteConversation(token, conversation.id);
      if (!mounted) return;
      _update(() {
        _inboxRevision++;
        _conversations.removeWhere((item) => item.id == conversation.id);
        if (_selected?.id == conversation.id) {
          _clearDeletedConversation();
        }
      });
      await _refreshInbox(quiet: true);
    } on ChatFailure catch (failure) {
      _showError(failure.message);
      if (failure.sessionEnded) _expireSession();
    } finally {
      _deletingConversations.remove(conversation.id);
      if (mounted) _update(() {});
    }
  }

  void _clearDeletedConversation() {
    final recipientId = _selected?.otherUserId;
    if (recipientId != null) {
      for (final message
          in _localOutbox.remove(recipientId) ?? const <ChatMessage>[]) {
        _sendingMessageIds.remove(message.clientMessageId);
        _pendingSendTargets.remove(message.clientMessageId);
      }
    }
    _selected = null;
    _showThread = false;
    _messages.clear();
    _composer.clear();
    _hasMore = false;
    _nextBeforeId = null;
    _loadingHistory = false;
    _loadingOlder = false;
  }
}
