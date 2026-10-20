import 'package:flutter/material.dart';
import 'package:uniconnect/features/career/model/career_models.dart';

class CareerPostDetailsDialog extends StatelessWidget {
  const CareerPostDetailsDialog({
    required this.post,
    required this.studentView,
    this.onApply,
    this.onToggleSave,
    super.key,
  });

  final CareerPost post;
  final bool studentView;
  final Future<void> Function(CareerPost post)? onApply;
  final Future<void> Function(CareerPost post)? onToggleSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final redacted = post.isRedacted;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 820),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title ?? 'Unavailable opportunity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (post.employmentType != null)
                        _DetailPill(
                          post.employmentType!.label,
                          Icons.work_outline,
                        ),
                      if (post.workMode != null)
                        _DetailPill(
                          post.workMode!.label,
                          Icons.location_on_outlined,
                        ),
                      if (post.status != CareerAvailability.published)
                        _DetailPill(post.status.label, Icons.info_outline),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    post.companyName ?? 'Details no longer available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (post.authorDisplayName != null) ...[
                    const SizedBox(height: 4),
                    Text('Shared by ${post.authorDisplayName}'),
                  ],
                  if (redacted) ...[
                    const SizedBox(height: 22),
                    Text(
                      'The author or administrator removed this opportunity. Its details are no longer available.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ] else ...[
                    if (post.location != null || post.salaryRange != null) ...[
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 18,
                        runSpacing: 10,
                        children: [
                          if (post.location != null)
                            _Meta(
                              icon: Icons.place_outlined,
                              label: post.location!,
                            ),
                          if (post.salaryRange != null)
                            _Meta(
                              icon: Icons.payments_outlined,
                              label: post.salaryRange!,
                            ),
                        ],
                      ),
                    ],
                    if (post.description != null)
                      _DetailSection(
                        title: 'About the opportunity',
                        body: post.description!,
                      ),
                    if (post.qualifications != null)
                      _DetailSection(
                        title: 'Qualifications',
                        body: post.qualifications!,
                      ),
                    if (post.skills.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Skills',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final skill in post.skills)
                            Chip(
                              avatar: Icon(
                                skill.required
                                    ? Icons.check_circle_outline
                                    : Icons.add_circle_outline,
                                size: 16,
                              ),
                              label: Text(
                                '${skill.name} · ${skill.required ? 'Required' : 'Preferred'}',
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (post.applicationChannels.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'How to apply',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        post.applicationChannels.length > 1
                            ? 'Choose an application channel when you apply.'
                            : 'This opportunity uses ${post.applicationChannels.first.label.toLowerCase()}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (studentView && onToggleSave != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await onToggleSave!(post);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(
                        post.saved
                            ? Icons.bookmark_remove_outlined
                            : Icons.bookmark_add_outlined,
                      ),
                      label: Text(post.saved ? 'Remove saved' : 'Save'),
                    ),
                  if (studentView && post.canApply && onApply != null) ...[
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => onApply!(post),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Apply'),
                    ),
                  ],
                  if (!studentView || (!post.canApply && onToggleSave == null))
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill(this.label, this.icon);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 16),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 17,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}
