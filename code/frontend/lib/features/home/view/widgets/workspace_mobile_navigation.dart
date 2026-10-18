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
    required this.busy,
    required this.onSelect,
    super.key,
  });
  final bool profileSelected;
  final String? selectedFeature;
  final bool homeEnabled;
  final bool administrator;
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
  Widget build(BuildContext context) => NavigationBar(
    backgroundColor: Theme.of(context).colorScheme.surface,
    indicatorColor: Theme.of(context).colorScheme.primary
        .withValues(alpha: .14),
    selectedIndex: profileSelected
        ? 4
        : selectedFeature == null
        ? 0
        : switch (selectedFeature) {
            'Home' => 0,
            'Discover' => 1,
            'Connections' => 2,
            'Messages' => 3,
            _ => 4,
          },
    labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
    onDestinationSelected: busy
        ? null
        : (index) {
            if (index == 4) {
              _more(context);
            } else {
              onSelect(['Home', 'Discover', 'Connections', 'Messages'][index]);
            }
          },
    destinations: [
      NavigationDestination(
        enabled: homeEnabled,
        icon: const Icon(Icons.home_outlined),
        label: 'Home',
      ),
      const NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        label: 'Connections',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Messages',
      ),
      const NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        label: 'More',
      ),
    ],
  );
}
