import 'package:flutter/material.dart';
import 'package:uniconnect/features/career/model/career_models.dart';

class CareerPostCard extends StatelessWidget {
  const CareerPostCard({
    required this.post,
    required this.onOpen,
    this.savedNote,
    this.showSavedNote = false,
    this.onApply,
    this.onToggleSave,
    this.onEditNote,
    this.onEdit,
    this.onClose,
    super.key,
  });

  final CareerPost post;
  final VoidCallback onOpen;
  final String? savedNote;
  final bool showSavedNote;
  final VoidCallback? onApply;
  final VoidCallback? onToggleSave;
  final VoidCallback? onEditNote;
  final VoidCallback? onEdit;
  final VoidCallback? onClose;

  String _deadline(DateTime? date) {
    if (date == null) return 'Deadline unavailable';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Apply by ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = post.title ?? 'Unavailable opportunity';
    final company = post.companyName ?? 'Details no longer available';
    final label = post.employmentType?.label ?? post.status.label;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          label: label,
                          icon: Icons.work_outline,
                          accent: true,
                        ),
                        if (post.workMode != null)
                          _Pill(
                            label: post.workMode!.label,
                            icon: post.workMode == CareerWorkMode.remote
                                ? Icons.public
                                : Icons.location_on_outlined,
                          ),
                        if (post.status != CareerAvailability.published)
                          _Pill(
                            label: post.status.label,
                            icon: Icons.info_outline,
                            warning: true,
                          ),
                      ],
                    ),
                  ),
                  if (onToggleSave != null)
                    IconButton(
                      tooltip: post.saved
                          ? 'Remove saved opportunity'
                          : 'Save opportunity',
                      onPressed: onToggleSave,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        post.saved ? Icons.bookmark : Icons.bookmark_border,
                        color: post.saved ? theme.colorScheme.primary : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                company,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (post.authorDisplayName != null) ...[
                const SizedBox(height: 3),
                Text(
                  'Shared by ${post.authorDisplayName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (post.description != null && post.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  post.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
              if (post.skills.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final skill in post.skills.take(5))
                      _SkillPill(skill: skill),
                    if (post.skills.length > 5)
                      _Pill(label: '+${post.skills.length - 5} more'),
                  ],
                ),
              ],
              if (showSavedNote) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: .6,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          savedNote?.isNotEmpty == true
                              ? savedNote!
                              : 'No private note added.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      if (onEditNote != null)
                        IconButton(
                          tooltip: 'Edit private note',
                          onPressed: onEditNote,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.status == CareerAvailability.published
                          ? _deadline(post.applicationDeadline)
                          : post.status.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (onEdit != null || onClose != null) ...[
                    if (onEdit != null)
                      IconButton(
                        tooltip: 'Edit opportunity',
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                    if (onClose != null)
                      IconButton(
                        tooltip: 'Close opportunity',
                        onPressed: onClose,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 19),
                      ),
                  ] else if (onApply != null)
                    FilledButton.tonalIcon(
                      onPressed: onApply,
                      icon: const Icon(Icons.open_in_new, size: 17),
                      label: const Text('Apply'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    this.icon,
    this.accent = false,
    this.warning = false,
  });

  final String label;
  final IconData? icon;
  final bool accent;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = warning
        ? theme.colorScheme.error
        : accent
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final background = warning
        ? theme.colorScheme.errorContainer.withValues(alpha: .45)
        : accent
        ? theme.colorScheme.primary.withValues(alpha: .09)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: .7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  const _SkillPill({required this.skill});
  final CareerSkill skill;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: .65),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      '${skill.name}${skill.required ? ' · Required' : ' · Preferred'}',
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}
