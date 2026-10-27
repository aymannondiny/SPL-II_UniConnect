part of '../chat_page.dart';

extension _ChatRecipients on _ChatPageState {
  Future<void> _resolveRecipient() async {
    final recipient = _pendingRecipient;
    final token = _token;
    if (recipient == null || token == null) return;
    final generation = ++_recipientGeneration;
    _update(() {
      _selected = null;
      _draftConnection = null;
      _composer.clear();
      _messages.clear();
      _showThread = false;
      _error = null;
    });
    try {
      final connections = await _repository.acceptedConnections(token);
      if (!mounted || generation != _recipientGeneration) return;
      _pendingRecipient = null;
      final permitted = connections.where(
        (item) => item.userId == recipient.userId,
      );
      if (permitted.isEmpty) {
        _update(
          () => _error = 'This person is no longer an accepted connection. Refresh Connections to check their status.',
        );
        return;
      }
      final existing = _conversations.where(
        (item) => item.otherUserId == recipient.userId,
      );
      if (existing.isNotEmpty) {
        _selectConversation(existing.first);
      } else {
        _selectConnection(permitted.first);
      }
    } on ChatFailure catch (failure) {
      if (!mounted || generation != _recipientGeneration) return;
      _update(() => _error = failure.message);
      if (failure.sessionEnded) _expireSession();
    }
  }

  void _selectConversation(ChatConversation conversation) {
    _composer.clear();
    final latest = conversation.latestVisibleMessage;
    _update(() {
      _selected = conversation;
      _draftConnection = null;
      _messages.clear();
      if (latest != null) _messages.add(latest);
      _restoreLocalMessages(conversation.otherUserId);
      _hasMore = false;
      _nextBeforeId = null;
      _loadingOlder = false;
      _loadingHistory = false;
      _showThread = true;
      _error = null;
    });
    _scrollToLatest();
    _loadHistory(conversation);
  }

  void _selectConnection(ChatConnection connection) {
    _composer.clear();
    _update(() {
      _selected = null;
      _draftConnection = connection;
      _messages.clear();
      _restoreLocalMessages(connection.userId);
      _hasMore = false;
      _loadingOlder = false;
      _loadingHistory = false;
      _showThread = true;
      _error = null;
    });
  }

  Future<void> _startConversation() async {
    final token = _token;
    if (token == null) return;
    try {
      final connections = await _repository.acceptedConnections(token);
      if (!mounted) return;
      final existingIds = _conversations
          .map((item) => item.otherUserId)
          .toSet();
      final eligible = connections
          .where((item) => !existingIds.contains(item.userId))
          .toList(growable: false);
      final chosen = await showDialog<ChatConnection>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Start a conversation'),
          content: SizedBox(
            width: 420,
            child: eligible.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'You already have conversations with all your accepted connections.',
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: eligible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final connection = eligible[index];
                      return ListTile(
                        leading: ChatAvatar(
                          name: connection.fullName,
                          size: 42,
                        ),
                        title: Text(connection.fullName),
                        subtitle: const Text('Accepted connection'),
                        onTap: () => Navigator.pop(dialogContext, connection),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (chosen != null) _selectConnection(chosen);
    } on ChatFailure catch (failure) {
      _showError(failure.message);
      if (failure.sessionEnded) _expireSession();
    }
  }
}
