import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_destinations.dart';

/// Scrollable navigation keeps every wireframe destination reachable on short screens.
class WorkspaceNavigation extends StatelessWidget {
  const WorkspaceNavigation({
    required this.profileSelected,
    this.selectedFeature,
    required this.homeEnabled,
    required this.administrator,
    this.access,
    required this.onSelect,
    super.key,
  });
  final bool profileSelected;
  final String? selectedFeature;
  final bool homeEnabled;
  final bool administrator;
  final WorkspaceAccess? access;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engineering = EngineeringTheme.active(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (final group in destinationsFor(
          access ??
              WorkspaceAccess(role: administrator ? 'SYSTEM_ADMIN' : 'STUDENT'),
        ).entries) ...[
          if (!engineering)
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
          for (final destination in group.value)
            if (destination.label != 'Administration' || administrator)
              engineering
                  ? _engineeringItem(
                      context,
                      route: destination.label,
                      label: destination.label == 'Home'
                          ? 'Dashboard'
                          : destination.label,
                      icon: destination.icon,
                    )
                  : _item(context, destination),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _engineeringItem(
    BuildContext context, {
    required String route,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final selectedRoute =
        selectedFeature ?? (profileSelected ? 'My profile' : 'Home');
    final selected = route == selectedRoute;
    final enabled = route != 'Home' || homeEnabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? const Color(0xFF741136) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: selected
              ? const BorderSide(color: AppTheme.engineeringAccent)
              : BorderSide.none,
        ),
        child: ListTile(
          dense: true,
          minTileHeight: 45,
          enabled: enabled,
          selected: selected,
          leading: Icon(icon, size: 22),
          title: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          onTap: enabled ? () => onSelect(route) : null,
        ),
      ),
    );
  }

  Widget _item(BuildContext context, WorkspaceDestination destination) {
    final theme = Theme.of(context);
    final engineering = EngineeringTheme.active(context);
    final selected =
        destination.label ==
        (selectedFeature ?? (profileSelected ? 'My profile' : 'Home'));
    final enabled = destination.label != 'Home' || homeEnabled;
    return Tooltip(
      message: destination.label,
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
            tileColor: engineering ? const Color(0x00160D19) : null,
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
