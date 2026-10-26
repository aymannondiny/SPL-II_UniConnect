part of '../project_dialogs.dart';

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.item});
  final ProjectRecommendation item;

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
              name: item.displayName,
              imageUrl: item.profilePhotoUrl,
              size: 46,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (item.departmentName != null)
                    Text(
                      item.departmentName!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final skill in item.matchedRequiredSkills)
                        Chip(
                          label: Text(skill),
                          avatar: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      for (final skill in item.matchedOptionalSkills)
                        Chip(
                          label: Text(skill),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
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
