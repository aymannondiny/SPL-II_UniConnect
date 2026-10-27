import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';

import '../../model/club_overview.dart';

/// Responsive summary cards use the same surfaces and typography as the workspace.
class ClubOverviewMetrics extends StatelessWidget {
  const ClubOverviewMetrics({
    required this.overview,
    required this.now,
    super.key,
  });
  final ClubOverview overview;
  final DateTime now;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 750 ? 3 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      final metrics = [
        (
          'Upcoming & live events',
          overview.upcomingAt(now).length,
          Icons.event_outlined,
        ),
        (
          'Published announcements',
          overview.publishedAt(now),
          Icons.campaign_outlined,
        ),
        ('Announcement drafts', overview.drafts, Icons.edit_note_outlined),
      ];
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: width,
              child: SectionCard(
                title: metric.$1,
                child: Row(
                  children: [
                    Icon(
                      metric.$3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${metric.$2}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
