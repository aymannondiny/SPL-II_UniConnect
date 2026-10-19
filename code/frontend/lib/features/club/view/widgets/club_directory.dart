import 'package:flutter/material.dart';

import '../../controller/campus_feed.dart';
import '../../model/club.dart';
import 'club_tile.dart';

class ClubDirectory extends StatelessWidget {
  const ClubDirectory({
    required this.feed,
    required this.selectedId,
    required this.onSelect,
    required this.onSearch,
    required this.searchController,
    super.key,
  });
  final CampusFeed<Club> feed;
  final int? selectedId;
  final ValueChanged<Club> onSelect;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Find your community',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: onSearch,
        decoration: InputDecoration(
          labelText: 'Search clubs by name or category',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Search clubs',
            onPressed: () => onSearch(searchController.text),
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
      ),
      const SizedBox(height: 16),
      ListenableBuilder(
        listenable: feed,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final club in feed.items)
                      SizedBox(
                        width: width,
                        child: ClubTile(
                          club: club,
                          selected: selectedId == club.id,
                          onTap: () => onSelect(club),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (feed.loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (feed.error != null) ...[
              Text(feed.error!),
              TextButton(
                onPressed: () => feed.load(reset: feed.items.isEmpty),
                child: const Text('Retry clubs'),
              ),
            ] else if (feed.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No clubs found. Try another name or category.'),
              )
            else if (feed.hasMore)
              TextButton(
                onPressed: () => feed.load(reset: false),
                child: const Text('Load more clubs'),
              ),
          ],
        ),
      ),
    ],
  );
}
