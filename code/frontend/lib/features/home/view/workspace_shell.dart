import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_sidebar.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_dimensions.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_topbar.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_mobile_navigation.dart';
import 'package:uniconnect/features/home/view/widgets/engineering_decorations.dart';

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
    this.access,
    this.contextSwitcher,
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
  final WorkspaceAccess? access;
  final Widget? contextSwitcher;
  WorkspaceAccess get permissions => access ?? WorkspaceAccess(role: role);
  void _select(String label) {
    if (label == 'Search') label = 'Discover';
    if (busy || !permissions.allows(label)) return;
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
    final engineering = EngineeringTheme.active(context);
    final compact =
        MediaQuery.sizeOf(context).width < workspaceCompactBreakpoint;
    final main = Column(
      children: [
        WorkspaceTopbar(
          compact: compact,
          name: name,
          busy: busy,
          onProfile: onProfile,
          onLogout: onLogout,
          onFeature: _select,
          discoveryEnabled: permissions.allows('Discover'),
          contextSwitcher: engineering ? contextSwitcher : null,
        ),
        if (!engineering) ?contextSwitcher,
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: AbsorbPointer(absorbing: busy, child: child),
        ),
      ],
    );
    final content = SafeArea(
      top: false,
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact)
            WorkspaceSidebar(
              access: permissions,
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
            child: engineering ? EngineeringBackdrop(child: main) : main,
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: engineering ? Colors.transparent : null,
      body: content,
      bottomNavigationBar: compact
          ? WorkspaceMobileNavigation(
              profileSelected: profileSelected,
              selectedFeature: selectedFeature,
              homeEnabled: onHome != null,
              access: permissions,
              administrator: role == 'SYSTEM_ADMIN',
              busy: busy,
              onSelect: _select,
            )
          : null,
    );
  }
}
