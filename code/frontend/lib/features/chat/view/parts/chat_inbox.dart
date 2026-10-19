part of '../chat_page.dart';

extension _ChatInbox on _ChatPageState {
  Future<void> _refreshInbox({bool quiet = false}) async {
    final token = _token;
    if (token == null || _inboxRequestActive) return;
    _inboxRequestActive = true;
    if (!quiet && mounted) _update(() => _loadingInbox = true);
    try {
      final rows = await _repository.conversations(token);
      if (!mounted) return;
      _update(() {
        _conversations = rows;
        _loadingInbox = false;
        _inboxLoaded = true;
        _error = null;
        if (_selected != null) {
          final updated = rows.where((item) => item.id == _selected!.id);
          if (updated.isNotEmpty) _selected = updated.first;
        }
      });
      if (_pendingRecipient != null) unawaited(_resolveRecipient());
      for (final conversation in rows) {
        final latest = conversation.latestVisibleMessage;
        if (latest != null &&
            latest.senderId != _myUserId &&
            latest.content != null &&
            latest.deliveredAt == null &&
            latest.readAt == null) {
          unawaited(_acknowledgeDelivery(latest));
        }
      }
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      _update(() {
        _loadingInbox = false;
        if (!quiet) _error = failure.message;
      });
      if (failure.sessionEnded) _expireSession();
    } finally {
      _inboxRequestActive = false;
    }
  }

  Future<void> _loadHistory(
    ChatConversation conversation, {
    bool quiet = false,
  }) async {
    final token = _token;
    if (token == null) return;
    final requestGeneration = ++_historyRequestGeneration;
    if (mounted) {
      _update(() {
        _loadingHistory = true;
        if (!quiet) _error = null;
      });
    }
    try {
      final result = await _repository.history(token, conversation.id);
      if (!mounted) return;
      if (requestGeneration != _historyRequestGeneration ||
          _selected?.id != conversation.id) {
        if (requestGeneration == _historyRequestGeneration) {
          _update(() => _loadingHistory = false);
        }
        return;
      }
      _update(() {
        if (quiet) {
          // A quiet refresh fetches the newest page, but the user may already
          // have loaded older pages. Keep that paging cursor so the next
          // "Load older messages" request continues from the oldest message
          // currently shown instead of fetching the newest page again.
          final preservePagination = _messages.isNotEmpty;
          final hasMore = _hasMore;
          final nextBeforeId = _nextBeforeId;
          final byId = {for (final message in _messages) message.id: message};
          for (final message in result.items) {
            byId[message.id] = message;
          }
          _messages
            ..clear()
            ..addAll(
              byId.values.toList()..sort((a, b) {
                final byTime = a.sentAt.compareTo(b.sentAt);
                return byTime != 0 ? byTime : a.id.compareTo(b.id);
              }),
            );
          _hasMore = preservePagination ? hasMore : result.hasMore;
          _nextBeforeId = preservePagination
              ? nextBeforeId
              : result.nextBeforeMessageId;
        } else {
          _messages
            ..clear()
            ..addAll(result.items);
          _hasMore = result.hasMore;
          _nextBeforeId = result.nextBeforeMessageId;
        }
        _loadingHistory = false;
        _error = null;
      });
      _refreshInbox(quiet: true);
      if (!quiet) _scrollToLatest();
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      if (requestGeneration != _historyRequestGeneration) return;
      _update(() {
        _loadingHistory = false;
        if (!quiet) _error = failure.message;
      });
      if (failure.sessionEnded) _expireSession();
    }
  }

  Future<void> _acknowledgeDelivery(ChatMessage message) async {
    if (!_deliveryAcknowledgements.add(message.id)) return;
    final token = _token;
    if (token == null) {
      _deliveryAcknowledgements.remove(message.id);
      return;
    }
    try {
      final updated = await _repository.acknowledgeDelivered(token, message.id);
      if (!mounted) return;
      _update(() {
        _conversations = _conversations
            .map((conversation) {
              if (conversation.latestVisibleMessage?.id != updated.id) {
                return conversation;
              }
              return ChatConversation(
                id: conversation.id,
                otherUserId: conversation.otherUserId,
                otherFullName: conversation.otherFullName,
                canSend: conversation.canSend,
                unreadCount: conversation.unreadCount,
                lastMessageAt: conversation.lastMessageAt,
                latestVisibleMessage: updated,
              );
            })
            .toList(growable: false);
        final index = _messages.indexWhere((item) => item.id == updated.id);
        if (index >= 0) _messages[index] = updated;
      });
    } on ChatFailure catch (failure) {
      _deliveryAcknowledgements.remove(message.id);
      if (failure.sessionEnded) _expireSession();
    } on Object {
      _deliveryAcknowledgements.remove(message.id);
    }
  }

  Future<void> _loadOlder() async {
    final conversation = _selected;
    final token = _token;
    final before = _nextBeforeId;
    if (conversation == null ||
        token == null ||
        before == null ||
        _loadingOlder) {
      return;
    }
    _update(() => _loadingOlder = true);
    try {
      final result = await _repository.history(
        token,
        conversation.id,
        beforeMessageId: before,
      );
      if (!mounted || _selected?.id != conversation.id) return;
      _update(() {
        final known = _messages.map((item) => item.id).toSet();
        _messages.insertAll(
          0,
          result.items.where((item) => !known.contains(item.id)),
        );
        _hasMore = result.hasMore;
        _nextBeforeId = result.nextBeforeMessageId;
        _loadingOlder = false;
      });
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      _update(() {
        _loadingOlder = false;
        _error = failure.message;
      });
      if (failure.sessionEnded) _expireSession();
    }
  }
}
