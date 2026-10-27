import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_mobile_destinations.dart';
import 'package:flutter/material.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_navigation.dart';

/// Keeps the most-used workspace destinations visible and exposes every other
/// destination through the complete More navigation sheet.
class WorkspaceMobileNavigation extends StatelessWidget {
  const WorkspaceMobileNavigation({
    required this.profileSelected,
    this.selectedFeature,
    required this.homeEnabled,
    required this.administrator,
    this.access,
    required this.busy,
    required this.onSelect,
    super.key,
  });
  final bool profileSelected;
  final String? selectedFeature;
  final bool homeEnabled;
  final bool administrator;
  final WorkspaceAccess? access;
  WorkspaceAccess get permissions =>
      access ??
      WorkspaceAccess(role: administrator ? 'SYSTEM_ADMIN' : 'STUDENT');
  final bool busy;
  final ValueChanged<String> onSelect;
  Future<void> _more(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            Text(
              'More in UniConnect',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: WorkspaceNavigation(
                access: permissions,
                profileSelected: profileSelected,
                selectedFeature: selectedFeature,
                homeEnabled: homeEnabled,
                administrator: administrator,
                onSelect: (label) {
                  Navigator.pop(sheetContext);
                  onSelect(label);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final items = mobileDestinationsFor(permissions);
    final selected = profileSelected ? 'My profile' : selectedFeature ?? 'Home';
    final index = items.indexWhere((item) => item.label == selected);
    return NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: Theme.of(context).colorScheme.primary
          .withValues(alpha: .14),
      selectedIndex: index < 0 ? items.length : index,
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
      onDestinationSelected: busy
          ? null
          : (index) {
              if (index == items.length) {
                _more(context);
              } else {
                onSelect(items[index].label);
              }
            },
      destinations: [
        for (final item in items)
          NavigationDestination(
            enabled: item.label != 'Home' || homeEnabled,
            icon: Icon(item.icon),
            label: item.label == 'Account management' ? 'Accounts' : item.label,
          ),
        const NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          label: 'More',
        ),
      ],
    );
  }
}
