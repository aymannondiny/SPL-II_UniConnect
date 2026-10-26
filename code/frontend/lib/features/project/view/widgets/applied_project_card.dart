part of '../project_finder_page.dart';

class _AppliedCard extends StatelessWidget {
  const _AppliedCard({required this.item, required this.onDetails});
  final AppliedProject item;
  final VoidCallback? onDetails;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final application = item.application;
    final project = item.project;
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.layers_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project?.title ?? 'Deleted project listing',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (compact) ...[
                    const SizedBox(height: 8),
                    _ProjectStatus(status: application.status),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    project == null
                        ? 'This listing was deleted by its owner.'
                        : 'Applied ${_formatDate(application.appliedAt)} · ${project.creatorDisplayName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 12),
              _ProjectStatus(status: application.status),
            ],
            if (onDetails != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDetails,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'View project',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
