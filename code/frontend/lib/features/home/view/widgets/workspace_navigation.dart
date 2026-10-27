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
    if (engineering) return _engineeringNavigation(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (final group in destinationsFor(
          access ??
              WorkspaceAccess(role: administrator ? 'SYSTEM_ADMIN' : 'STUDENT'),
        ).entries) ...[
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
              _item(context, destination),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _engineeringNavigation(BuildContext context) {
    final available =
        access ??
        WorkspaceAccess(role: administrator ? 'SYSTEM_ADMIN' : 'STUDENT');
    final items = <(String, String, IconData)>[
      ('Home', 'Dashboard', Icons.home_outlined),
      ('Discover', 'Discover', Icons.search),
      ('Connections', 'Connections', Icons.people_outline),
      ('Clubs & events', 'Clubs', Icons.hexagon_outlined),
      ('Project finder', 'Projects', Icons.layers_outlined),
      ('Career board', 'Career', Icons.work_outline),
      ('Mentorship', 'Mentorship', Icons.school_outlined),
      ('Clubs & events', 'Announcements', Icons.campaign_outlined),
      ('Clubs & events', 'Events', Icons.event_outlined),
      ('Messages', 'Chat', Icons.chat_bubble_outline),
    ].where((item) => available.allows(item.$1)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 26, 12, 8),
      children: [
        for (final item in items)
          _engineeringItem(
            context,
            route: item.$1,
            label: item.$2,
            icon: item.$3,
          ),
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
    final selected =
        route == selectedRoute &&
        !const {'Announcements', 'Events'}.contains(label);
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
