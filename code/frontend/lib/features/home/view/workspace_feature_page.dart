import 'package:flutter/material.dart';
import 'package:uniconnect/features/home/view/widgets/campus_features.dart';

/// Keeps every workspace destination reachable while its dedicated feature is
/// being connected to the app's data services.
class WorkspaceFeaturePage extends StatelessWidget {
  const WorkspaceFeaturePage({required this.feature, super.key});

  final String feature;

  @override
  Widget build(BuildContext context) {
    final details = campusFeatures.where((item) => item.title == feature);
    final item = details.isEmpty ? null : details.first;
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item?.icon ?? Icons.dashboard_outlined,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(feature, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  item?.description ?? 'Your UniConnect workspace.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Text(
                  'This section is available in your workspace. Its dedicated tools are being connected.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
