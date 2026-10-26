part of '../project_finder_page.dart';

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.owned,
    required this.manageOnly,
    required this.onDetails,
    required this.onManage,
    required this.onApply,
  });

  final ProjectListing project;
  final bool owned;
  final bool manageOnly;
  final VoidCallback onDetails;
  final VoidCallback onManage;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canApply = !owned && project.canApply && !manageOnly;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 290),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ProjectStatus(status: project.availability),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  project.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                if (project.skills.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final skill in project.skills.take(4))
                        Chip(
                          label: Text(skill.name),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: skill.isRequired
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                        ),
                      if (project.skills.length > 4)
                        Chip(
                          label: Text('+${project.skills.length - 4}'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${project.membershipCount} of ${project.teamSizeLimit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value:
                              (project.membershipCount / project.teamSizeLimit)
                                  .clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: colors.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        _initials(project.creatorDisplayName),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          project.creatorDisplayName,
                          project.creatorDepartmentCode,
                        ].whereType<String>().join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      'By ${_formatDate(project.applicationDeadline)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: owned ? onManage : onDetails,
                        icon: Icon(
                          owned ? Icons.settings_outlined : Icons.open_in_new,
                          size: 17,
                        ),
                        label: Text(owned ? 'Manage' : 'Details'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: canApply ? onApply : null,
                        child: Text(
                          owned
                              ? 'Your post'
                              : switch (project.currentApplicationStatus) {
                                  'PENDING' => 'Applied',
                                  'ACCEPTED' => 'Accepted',
                                  'REJECTED' => 'Declined',
                                  'CANCELLED_PROJECT_DELETED' => 'Cancelled',
                                  _ => project.full ? 'Full' : 'Apply',
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
