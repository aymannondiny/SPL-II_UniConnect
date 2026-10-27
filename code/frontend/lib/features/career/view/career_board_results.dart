part of 'career_board_page.dart';

extension _CareerBoardResults on _CareerBoardPageState {
  Widget _postContent(ThemeData theme, List<CareerPost> posts) {
    if (_error != null && posts.isEmpty) return const SizedBox.shrink();
    if (posts.isEmpty) {
      return _emptyState(
        theme,
        icon: _alumni && _savedTab
            ? Icons.work_outline
            : Icons.search_off_outlined,
        title: _alumni && _savedTab
            ? 'No opportunities yet'
            : _hasActiveFilters
            ? 'No matching opportunities'
            : 'No active opportunities yet',
        message: _alumni && _savedTab
            ? 'Share an internship or job opening to help students take their next step.'
            : _hasActiveFilters
            ? 'No active roles match these filters. Clear them to see all available opportunities.'
            : 'There are no active roles published right now. Check back as alumni share new opportunities.',
        action: _alumni && _savedTab
            ? FilledButton.icon(
                onPressed: _createPost,
                icon: const Icon(Icons.add),
                label: const Text('Post an opportunity'),
              )
            : _hasActiveFilters
            ? OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              )
            : OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
      );
    }
    if (!_savedTab) {
      return _jobGrid(
        posts,
        (post) => CareerPostCard(
          post: post,
          onOpen: () => _showDetails(post),
          onApply: _student && post.canApply && !_busyPosts.contains(post.id)
              ? () => _showDetails(post)
              : null,
          onToggleSave: !_student || _busyPosts.contains(post.id)
              ? null
              : () => _toggleSave(post),
        ),
      );
    }
    return _jobGrid(
      posts,
      (post) => CareerPostCard(
        post: post,
        onOpen: () => _showDetails(post),
        onEdit: _canEdit(post) ? () => _editPost(post) : null,
        onClose: _owns(post) && post.status == CareerAvailability.published
            ? () => _closePost(post)
            : null,
      ),
    );
  }

  Widget _savedContent(ThemeData theme) {
    if (_error != null && _saved.isEmpty) return const SizedBox.shrink();
    if (_saved.isEmpty) {
      return _emptyState(
        theme,
        icon: Icons.bookmark_border,
        title: 'Your saved opportunities will appear here',
        message:
            'Save a post to keep it handy and add a private note for yourself.',
        action: TextButton.icon(
          onPressed: () => _switchTab(false),
          icon: const Icon(Icons.search),
          label: const Text('Browse opportunities'),
        ),
      );
    }
    return _jobGrid(_saved.map((item) => item.post).toList(), (post) {
      final saved = _saved.firstWhere((item) => item.post.id == post.id);
      return CareerPostCard(
        post: post,
        onOpen: () => _showDetails(post),
        showSavedNote: true,
        savedNote: saved.note,
        onEditNote: () => _editNote(saved),
        onApply: post.canApply ? () => _showDetails(post) : null,
        onToggleSave: _busyPosts.contains(post.id)
            ? null
            : () => _toggleSave(post),
      );
    });
  }

  Widget _jobGrid(List<CareerPost> posts, Widget Function(CareerPost) card) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 2 : 1;
          final gap = 16.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final post in posts)
                SizedBox(width: width, child: card(post)),
            ],
          );
        },
      );

  bool _owns(CareerPost post) =>
      _alumni &&
      (widget.currentUserId == null
          ? _savedTab
          : post.authorUserId == widget.currentUserId);
  bool _canEdit(CareerPost post) {
    final deadline = post.applicationDeadline;
    return _owns(post) &&
        post.status == CareerAvailability.published &&
        deadline != null &&
        !DateUtils.dateOnly(deadline)
            .isBefore(DateUtils.dateOnly(DateTime.now()));
  }

  Widget _emptyState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
      ),
    ),
    child: Column(
      children: [
        Icon(icon, size: 38, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    ),
  );

  Widget _errorPanel(ThemeData theme) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.errorContainer.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.cloud_off_outlined, color: theme.colorScheme.error),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!)),
        TextButton.icon(
          onPressed: _loading ? null : () => _load(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _restricted(BuildContext context) {
    final theme = Theme.of(context);
    return _emptyState(
      theme,
      icon: Icons.lock_outline,
      title: 'Career Board access is limited',
      message: 'Students can browse and save opportunities. Alumni can publish and manage their own posts.',
    );
  }
}
