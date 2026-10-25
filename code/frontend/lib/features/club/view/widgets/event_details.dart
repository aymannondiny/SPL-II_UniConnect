import 'package:uniconnect/features/reporting/view/report_content_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/club_event.dart';
import '../../model/publication_time.dart';

class EventDetails extends StatelessWidget {
  const EventDetails({required this.event, super.key});
  final ClubEvent event;

  @override
  Widget build(BuildContext context) {
    final registration = event.registrationAt(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportContentButton(targetType: 'EVENT', targetId: event.id),
        Text(event.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(event.clubName),
        const SizedBox(height: 16),
        SelectableText(event.description),
        const SizedBox(height: 16),
        Text('Starts: ${publicationDate(event.startsAt)}'),
        Text('Ends: ${publicationDate(event.endsAt)}'),
        const Text('Times shown in your local timezone.'),
        if (event.location != null) ...[
          const SizedBox(height: 12),
          Text('Location: ${event.location}'),
        ],
        if (event.registrationDeadline != null) ...[
          const SizedBox(height: 12),
          Text(
            'Registration deadline: ${publicationDate(event.registrationDeadline!)}',
          ),
        ],
        const SizedBox(height: 16),
        if (registration != null) ...[
          const Text('Register with the organizer using this external link:'),
          const SizedBox(height: 8),
          SelectableText(registration.toString()),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy registration link'),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: registration.toString()),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registration link copied.')),
                );
              }
            },
          ),
        ] else
          Text(
            event.registrationUrl == null
                ? 'No registration link provided.'
                : 'Registration is closed or the link is unavailable.',
          ),
      ],
    );
  }
}
