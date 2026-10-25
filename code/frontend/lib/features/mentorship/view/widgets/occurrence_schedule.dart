import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_occurrence.dart';

class OccurrenceSchedule extends StatelessWidget {
  const OccurrenceSchedule({required this.occurrences, super.key});

  final List<MentorshipOccurrence> occurrences;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Schedule · Asia/Dhaka',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final occurrence in occurrences)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '${occurrence.startsAt.toIso8601String().substring(0, 10)} · '
              '${occurrence.startsAt.toIso8601String().substring(11, 16)}–'
              '${occurrence.endsAt.toIso8601String().substring(11, 16)} · ${occurrence.label}',
            ),
          ),
      ],
    );
  }
}
