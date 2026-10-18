import 'package:flutter/material.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_sidebar.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_dimensions.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_topbar.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_mobile_navigation.dart';

/// Responsive workspace chrome with a bounded content area for retained tabs.
class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({
    required this.child,
    required this.name,
    required this.profileSelected,
    this.selectedFeature,
    required this.onHome,
    required this.onProfile,
    required this.onLogout,
    required this.onFeature,
    required this.busy,
    this.role = 'STUDENT',
    this.error,
    super.key,
  });
  final Widget child;
  final String name;
  final String role;
  final bool profileSelected;
  final String? selectedFeature;
  final VoidCallback? onHome;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final ValueChanged<String> onFeature;
  final bool busy;
  final String? error;
  void _select(String label) {
    if (busy) return;
    switch (label) {
      case 'Home':
        onHome?.call();
      case 'My profile':
        onProfile();
      default:
        onFeature(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < workspaceCompactBreakpoint;
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact)
            WorkspaceSidebar(
              name: name,
              role: role,
              profileSelected: profileSelected,
              selectedFeature: selectedFeature,
              homeEnabled: onHome != null,
              busy: busy,
              onSelect: _select,
              onLogout: onLogout,
            ),
          Expanded(
            child: Column(
              children: [
                WorkspaceTopbar(
                  compact: compact,
                  name: name,
                  busy: busy,
                  onProfile: onProfile,
                  onLogout: onLogout,
                  onFeature: onFeature,
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: compact
          ? WorkspaceMobileNavigation(
              profileSelected: profileSelected,
              selectedFeature: selectedFeature,
              homeEnabled: onHome != null,
              administrator: role == 'SYSTEM_ADMIN',
              busy: busy,
              onSelect: _select,
            )
          : null,
    );
  }
}
