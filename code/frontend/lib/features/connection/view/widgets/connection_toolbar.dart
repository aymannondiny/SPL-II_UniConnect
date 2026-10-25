import 'package:flutter/material.dart';

import '../../data/connection_repository.dart';
import '../../model/member_filters.dart';
import 'member_filter_panel.dart';

/// Search and tab controls, independently responsive from list results.
class ConnectionToolbar extends StatelessWidget {
  const ConnectionToolbar({
    required this.discover,
    required this.busy,
    required this.loading,
    required this.repository,
    required this.search,
    required this.discoverySearch,
    required this.total,
    required this.counts,
    required this.tab,
    required this.onTab,
    required this.onMode,
    required this.onConnectionSearch,
    required this.onDiscoverSearch,
    required this.onFilters,
    super.key,
  });
  final bool discover;
  final bool busy;
  final bool loading;
  final ConnectionRepository repository;
  final TextEditingController search;
  final TextEditingController discoverySearch;
  final int total;
  final List<int> counts;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<bool> onMode;
  final VoidCallback onConnectionSearch;
  final VoidCallback onDiscoverSearch;
  final ValueChanged<MemberFilters> onFilters;

  Widget tabButton(String label, int index, int count) => ChoiceChip(
    label: Text('$label  $count'),
    selected: tab == index,
    onSelected: busy ? null : (_) => onTab(index),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discover ? 'Discover people' : 'Connections',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    discover
                        ? 'Find students and alumni, then start a connection.'
                        : 'Requests and people you know.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: busy
                  ? null
                  : discover
                  ? onDiscoverSearch
                  : onConnectionSearch,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Discover'),
              selected: discover,
              onSelected: busy ? null : (_) => onMode(true),
            ),
            ChoiceChip(
              label: const Text('Connections'),
              selected: !discover,
              onSelected: busy ? null : (_) => onMode(false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!discover) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tabButton('Connected', 0, counts[0]),
              tabButton('Received', 1, counts[1]),
              tabButton('Sent', 2, counts[2]),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: search,
            onSubmitted: (_) => onConnectionSearch(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Filter this list by name',
              suffixIcon: IconButton(
                onPressed: () {
                  search.clear();
                  onConnectionSearch();
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: discoverySearch,
                  onSubmitted: (_) => onDiscoverSearch(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by name',
                    suffixIcon: IconButton(
                      onPressed: onDiscoverSearch,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: loading ? null : onDiscoverSearch,
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$total people',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (discover)
          MemberFilterPanel(
            repository: repository,
            onApply: (filters) {
              onFilters(filters);
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
