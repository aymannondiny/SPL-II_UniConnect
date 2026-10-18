import 'package:flutter/material.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_destinations.dart';

/// Scrollable navigation keeps every wireframe destination reachable on short screens.
class WorkspaceNavigation extends StatelessWidget {
  const WorkspaceNavigation({
    required this.profileSelected,
    this.selectedFeature,
    required this.homeEnabled,
    required this.administrator,
    required this.onSelect,
    super.key,
  });
  final bool profileSelected;
  final String? selectedFeature;
  final bool homeEnabled;
  final bool administrator;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (final group in workspaceGroups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
            child: Text(
              group.key,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final destination in group.value) _item(context, destination),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _item(BuildContext context, WorkspaceDestination destination) {
    final theme = Theme.of(context);
    final selected =
        destination.label ==
        (selectedFeature ?? (profileSelected ? 'My profile' : 'Home'));
    final enabled =
        (destination.label != 'Home' || homeEnabled) &&
        (destination.label != 'Administration' || administrator);
    return Tooltip(
      message: destination.label == 'Administration' && !administrator
          ? 'Only system administrators can access administration.'
          : destination.label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            dense: true,
            minTileHeight: 46,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            selected: selected,
            selectedTileColor: theme.colorScheme.primary.withValues(alpha: .13),
            selectedColor: theme.colorScheme.primary,
            enabled: enabled,
            leading: Icon(destination.icon, size: 21),
            title: Text(
              destination.label,
              style: const TextStyle(fontSize: 14),
            ),
            trailing: destination.soon
                ? const Text('Soon', style: TextStyle(fontSize: 11))
                : null,
            onTap: enabled ? () => onSelect(destination.label) : null,
          ),
        ),
      ),
    );
  }
}
