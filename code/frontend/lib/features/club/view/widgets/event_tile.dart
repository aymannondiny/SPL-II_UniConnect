import 'package:flutter/material.dart';

import '../../model/club_event.dart';
import '../../model/publication_time.dart';

class EventTile extends StatelessWidget {
  const EventTile({required this.event, required this.onOpen, super.key});
  final ClubEvent event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.event_outlined, color: theme.colorScheme.primary),
            Text(
              event.timingAt(DateTime.now()),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(event.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(event.clubName, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Text(publicationDate(event.startsAt)),
        if (event.location != null) ...[
          const SizedBox(height: 6),
          Text(event.location!),
        ],
        TextButton(onPressed: onOpen, child: const Text('View event')),
      ],
    );
  }
}
