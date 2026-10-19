import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';

import '../../controller/campus_feed.dart';

class CampusFeedSection<T> extends StatelessWidget {
  const CampusFeedSection({
    required this.title,
    required this.feed,
    required this.emptyMessage,
    required this.itemBuilder,
    super.key,
  });
  final String title;
  final CampusFeed<T> feed;
  final String emptyMessage;
  final Widget Function(T) itemBuilder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: feed,
    builder: (context, _) => SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in feed.items) ...[
            itemBuilder(item),
            const Divider(height: 32),
          ],
          if (feed.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (feed.error != null) ...[
            Text(feed.error!, semanticsLabel: 'Error: ${feed.error}'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => feed.load(reset: feed.items.isEmpty),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ] else if (feed.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(emptyMessage),
            )
          else if (feed.hasMore)
            OutlinedButton(
              onPressed: () => feed.load(reset: false),
              child: Text('Load more ${title.toLowerCase()}'),
            ),
        ],
      ),
    ),
  );
}
