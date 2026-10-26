part of '../project_finder_page.dart';

extension _ProjectPageHeader on _ProjectFinderPageState {
  Widget _pageHeader(ThemeData theme) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      final actions = Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _showCandidateSearch(),
            icon: const Icon(Icons.person_search_outlined, size: 18),
            label: const Text('Find teammates'),
          ),
          FilledButton.icon(
            onPressed: _controller.mutating ? null : _createProject,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Post a project'),
          ),
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Project finder',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton.outlined(
                  onPressed: _controller.refreshActiveTab,
                  icon: const Icon(Icons.refresh, size: 19),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Find teammates or join a project that needs your skills.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            actions,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project finder',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Find teammates or join a project that needs your skills.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  onPressed: _controller.refreshActiveTab,
                  icon: const Icon(Icons.refresh, size: 19),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 10),
                actions,
              ],
            ),
        ],
      );
    },
  );

  Widget _tabBar(ThemeData theme) => Container(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
        ),
      ),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabItem(
            'Open projects',
            Icons.layers_outlined,
            ProjectFinderTab.open,
            theme,
          ),
          _tabItem(
            'My posts',
            Icons.folder_open_outlined,
            ProjectFinderTab.mine,
            theme,
          ),
          _tabItem(
            'Applied',
            Icons.assignment_outlined,
            ProjectFinderTab.applied,
            theme,
          ),
        ],
      ),
    ),
  );

  Widget _tabItem(
    String label,
    IconData icon,
    ProjectFinderTab tab,
    ThemeData theme,
  ) {
    final selected = _controller.activeTab == tab;
    final count = switch (tab) {
      ProjectFinderTab.open => _controller.openTotal,
      ProjectFinderTab.mine => _controller.myTotal,
      ProjectFinderTab.applied => _controller.appliedTotal,
    };
    return InkWell(
      onTap: () => _controller.selectTab(tab),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: .12)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
