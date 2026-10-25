part of '../project_dialogs.dart';

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate});
  final ProjectCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(
              name: candidate.fullName,
              imageUrl: candidate.profilePhotoUrl,
              size: 46,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          candidate.fullName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (candidate.connectionStatus == 'ACCEPTED')
                        const Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('Connected'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      candidate.departmentName,
                      candidate.programmeName,
                      if (candidate.yearOfStudy != null)
                        'Year ${candidate.yearOfStudy}',
                    ].whereType<String>().join(' · '),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (candidate.skills.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final skill in candidate.skills.take(8))
                          Chip(
                            label: Text(
                              '${skill.name} · ${skill.kind == 'REQUIRED' ? 'Required' : 'Optional'}',
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (candidate.projectAvailable != null)
              Tooltip(
                message: candidate.projectAvailable!
                    ? 'Open to project work'
                    : 'Not currently open to project work',
                child: Icon(
                  candidate.projectAvailable!
                      ? Icons.handshake_outlined
                      : Icons.pause_circle_outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
