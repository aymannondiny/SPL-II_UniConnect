import 'package:flutter/material.dart';

import '../../model/club_announcement.dart';
import '../../model/publication_time.dart';

class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({
    required this.announcement,
    required this.onOpen,
    super.key,
  });
  final ClubAnnouncement announcement;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              announcement.clubName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (announcement.priority != 'NORMAL')
              Text(
                announcement.priority,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(announcement.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          publicationDate(
            announcement.publishedAt ??
                announcement.expiresAt ??
                DateTime.now(),
          ),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Text(
          announcement.content,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        TextButton(onPressed: onOpen, child: const Text('Read announcement')),
      ],
    );
  }
}
