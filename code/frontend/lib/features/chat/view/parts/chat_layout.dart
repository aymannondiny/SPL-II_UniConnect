part of '../chat_page.dart';

extension _ChatLayout on _ChatPageState {
  Widget _buildPage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedName = _selected?.otherFullName ?? _draftConnection?.fullName;
    if (widget.embedded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              MediaQuery.sizeOf(context).width < workspaceCompactBreakpoint;
          final horizontalPadding = compact ? 8.0 : 24.0;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              compact ? 10 : 20,
            ),
            child: _messagePanel(
              colors,
              compact: compact,
              selectedName: selectedName,
            ),
          );
        },
      );
    }
    return ScaffoldMessenger(
      key: _pageKey,
      child: Scaffold(
        bottomNavigationBar:
            MediaQuery.sizeOf(context).width < workspaceCompactBreakpoint
            ? WorkspaceMobileNavigation(
                profileSelected: false,
                selectedFeature: 'Messages',
                homeEnabled: true,
                administrator:
                    widget.sessionController.account?.platformRole ==
                    'SYSTEM_ADMIN',
                busy: widget.sessionController.busy,
                onSelect: (feature) {
                  if (feature == 'Messages') {
                    _update(() => _showThread = false);
                  } else {
                    _openWorkspaceFeature(feature);
                  }
                },
              )
            : null,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < workspaceCompactBreakpoint;
              final showWorkspaceSidebar =
                  constraints.maxWidth >= workspaceCompactBreakpoint;
              return Row(
                children: [
                  if (showWorkspaceSidebar) _sidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _topBar(compact: compact),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 8 : 24,
                              10,
                              compact ? 8 : 24,
                              compact ? 10 : 20,
                            ),
                            child: _messagePanel(
                              colors,
                              compact: compact,
                              selectedName: selectedName,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _messagePanel(
    ColorScheme colors, {
    required bool compact,
    required String? selectedName,
  }) => SizedBox(
    width: double.infinity,
    height: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .48)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Row(
          children: [
            if (!compact || !_showThread)
              if (compact)
                Expanded(child: _inboxPane(colors))
              else
                SizedBox(width: 320, child: _inboxPane(colors)),
            if (!compact)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: colors.outlineVariant.withValues(alpha: .65),
              ),
            if (!compact || _showThread)
              Expanded(
                child: _threadPane(colors, selectedName, compact: compact),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _inboxPane(ColorScheme colors) {
    final filtered = _conversations
        .where((item) {
          final query = _search.text.trim().toLowerCase();
          return query.isEmpty ||
              item.otherFullName.toLowerCase().contains(query);
        })
        .toList(growable: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Messages',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Start a conversation',
                onPressed: _startConversation,
                icon: const Icon(Icons.edit_square),
              ),
            ],
          ),
        ),
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextField(
              controller: _search,
              onChanged: (_) => _update(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search conversations',
                isDense: true,
              ),
            ),
          ),
        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: .65)),
        Expanded(
          child: _loadingInbox && _conversations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? ChatEmptyInbox(onStart: _startConversation)
              : RefreshIndicator(
                  onRefresh: _refreshInbox,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final active = item.id == _selected?.id;
                      return ChatConversationTile(
                        conversation: item,
                        selected: active,
                        onTap: () => _selectConversation(item),
                      );
                    },
                  ),
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: TextStyle(color: colors.error)),
          ),
      ],
    );
  }
}
