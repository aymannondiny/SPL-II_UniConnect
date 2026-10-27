part of '../chat_page.dart';

extension _ChatThread on _ChatPageState {
  Widget _threadPane(
    ColorScheme colors,
    String? selectedName, {
    required bool compact,
  }) {
    if (selectedName == null) {
      return ChatWelcomePane(onStart: _startConversation);
    }
    final canSend = _selected?.canSend ?? true;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 24,
            vertical: compact ? 16 : 20,
          ),
          foregroundDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: colors.primary, width: 3)),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            border: Border(
              bottom: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .65),
              ),
            ),
          ),
          child: Row(
            children: [
              if (compact)
                IconButton(
                  tooltip: 'Back to inbox',
                  onPressed: () => _update(() => _showThread = false),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ChatAvatar(name: selectedName, size: 44, tonal: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: canSend
                                ? colors.primary
                                : colors.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          canSend ? 'Connected' : 'Chat history',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_selected != null)
                IconButton(
                  tooltip: 'Reload conversation',
                  onPressed: () => _loadHistory(_selected!),
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
        ),
        Expanded(
          child: ChatRibbonBackground(
            child: Column(
              children: [
                Expanded(
                  child: _loadingHistory && _messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                      ? ChatEmptyThread(name: selectedName)
                      : ListView.builder(
                          controller: _messageList,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 16 : 28,
                            vertical: 22,
                          ),
                          itemCount: _messages.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_hasMore && index == 0) {
                              return Center(
                                child: TextButton.icon(
                                  onPressed: _loadingOlder ? null : _loadOlder,
                                  icon: _loadingOlder
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.history_rounded),
                                  label: const Text('Load older messages'),
                                ),
                              );
                            }
                            final messageIndex = index - (_hasMore ? 1 : 0);
                            final message = _messages[messageIndex];
                            final own = message.senderId == _myUserId;
                            final day = message.sentAt.toLocal();
                            final startsDay =
                                messageIndex == 0 ||
                                !DateUtils.isSameDay(
                                  day,
                                  _messages[messageIndex - 1].sentAt.toLocal(),
                                );
                            final now = DateTime.now();
                            final dayLabel = DateUtils.isSameDay(day, now)
                                ? 'Today'
                                : DateUtils.isSameDay(
                                    day,
                                    DateTime(now.year, now.month, now.day - 1),
                                  )
                                ? 'Yesterday'
                                : MaterialLocalizations.of(context)
                                      .formatMediumDate(day);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (startsDay)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                        top: 2,
                                      ),
                                      child: Text(
                                        dayLabel.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                              letterSpacing: .8,
                                            ),
                                      ),
                                    ),
                                  ),
                                ChatMessageBubble(
                                  message: message,
                                  own: own,
                                  onDeleteSelf: () =>
                                      _deleteMessage(message, false),
                                  onDeleteEveryone: own
                                      ? () => _deleteMessage(message, true)
                                      : null,
                                ),
                              ],
                            );
                          },
                        ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  ),
                if (!canSend)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    color: Theme.of(context).cardTheme.color ?? colors.surface,
                    child: const Text(
                      'This connection is no longer active. You can still read and manage your chat history.',
                    ),
                  )
                else
                  _composerBar(colors, compact: compact),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _composerBar(ColorScheme colors, {required bool compact}) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        compact ? 12 : 22,
        0,
        compact ? 12 : 22,
        compact ? 12 : 22,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .65),
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: colors.onSurface.withValues(alpha: .04),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.primary, width: 2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _composer,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 5000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => _update(() {}),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Write a message',
                    prefixIcon: PopupMenuButton<String>(
                      tooltip: 'Insert emoji',
                      icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                      onSelected: (emoji) {
                        final value = _composer.value;
                        final selection = value.selection;
                        final start = selection.isValid
                            ? selection.start
                            : value.text.length;
                        final end = selection.isValid
                            ? selection.end
                            : value.text.length;
                        final text = value.text.replaceRange(start, end, emoji);
                        if (text.length > 5000) return;
                        _composer.value = TextEditingValue(
                          text: text,
                          selection: TextSelection.collapsed(
                            offset: start + emoji.length,
                          ),
                        );
                        _update(() {});
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: '😊', child: Text('😊  Smile')),
                        PopupMenuItem(
                          value: '👍',
                          child: Text('👍  Thumbs up'),
                        ),
                        PopupMenuItem(value: '❤️', child: Text('❤️  Heart')),
                        PopupMenuItem(
                          value: '🎉',
                          child: Text('🎉  Celebrate'),
                        ),
                        PopupMenuItem(value: '📚', child: Text('📚  Books')),
                        PopupMenuItem(value: '☕', child: Text('☕  Coffee')),
                      ],
                    ),
                    counterText: '',
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 46,
                width: 46,
                child: Tooltip(
                  message: 'Send message',
                  child: FilledButton(
                    onPressed: _sending || _composer.text.trim().isEmpty
                        ? null
                        : _sendMessage,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: _sending
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.north_east_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
