import 'package:flutter/material.dart';
import 'package:uniconnect/features/home/view/widgets/campus_features.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    required this.feature,
    required this.onTap,
    this.compact = false,
    super.key,
  });
  final CampusFeature feature;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = Container(
      padding: EdgeInsets.all(feature.featured && !compact ? 18 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: .13),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
          bottom: Radius.circular(12),
        ),
      ),
      child: Icon(feature.icon, color: theme.colorScheme.primary),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature.title,
          style:
              (feature.featured && !compact
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(feature.description, style: theme.textTheme.bodyMedium),
      ],
    );
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: .18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 0 : 232),
          padding: const EdgeInsets.all(20),
          decoration: feature.featured
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: .12),
                      Colors.transparent,
                    ],
                  ),
                )
              : null,
          child: compact
              ? Row(
                  children: [
                    icon,
                    const SizedBox(width: 16),
                    Expanded(child: body),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        icon,
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: .1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            feature.tag,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    body,
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            feature.title == 'My profile'
                                ? 'Open'
                                : feature.title == 'Administration' &&
                                      onTap == null
                                ? 'Administrator access required'
                                : 'Coming soon',
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
