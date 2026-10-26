part of '../project_finder_page.dart';

class _ProjectStatus extends StatelessWidget {
  const _ProjectStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color color = switch (status) {
      'AVAILABLE' || 'OPEN' || 'ACCEPTED' => colors.primary,
      'PENDING' => colors.secondary,
      'FULL' => colors.tertiary,
      'CLOSED' ||
      'EXPIRED' ||
      'REJECTED' ||
      'CANCELLED_PROJECT_DELETED' => colors.error,
      _ => colors.onSurfaceVariant,
    };
    final label = status
        .toLowerCase()
        .split('_')
        .map(
          (part) => part.isEmpty
              ? ''
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
