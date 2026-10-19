import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';

import '../../model/club.dart';

class ClubProfile extends StatelessWidget {
  const ClubProfile({required this.club, super.key});
  final Club club;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: club.name,
    subtitle: club.category,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(club.description),
        if (club.contactEmail != null) ...[
          const SizedBox(height: 12),
          SelectableText('Contact: ${club.contactEmail}'),
        ],
        if (club.status == 'PUBLISHING_SUSPENDED') ...[
          const SizedBox(height: 12),
          const Text(
            'Publishing is paused. Existing announcements and events remain available.',
          ),
        ],
      ],
    ),
  );
}
