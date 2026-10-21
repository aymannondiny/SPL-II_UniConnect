import 'package:flutter/material.dart';

class MentorshipSectionHeader extends StatelessWidget {
  const MentorshipSectionHeader({
    required this.title,
    required this.description,
    this.count,
    this.countLabel,
    super.key,
  });

  final String title;
  final String description;
  final int? count;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final countLabelText = count == null
            ? null
            : '$count ${countLabel ?? 'items'}';
        final countChip = countLabelText == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  countLabelText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );

        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        );

        if (countChip == null) return heading;
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 8), countChip],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 12),
            countChip,
          ],
        );
      },
    );
  }
}
