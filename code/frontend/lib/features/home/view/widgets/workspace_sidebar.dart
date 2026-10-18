import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/view/widgets/brand_mark.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_dimensions.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_navigation.dart';

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({
    required this.name,
    required this.role,
    required this.profileSelected,
    this.selectedFeature,
    required this.homeEnabled,
    required this.busy,
    required this.onSelect,
    required this.onLogout,
    super.key,
  });
  final String name;
  final String role;
  final bool profileSelected;
  final String? selectedFeature;
  final bool homeEnabled;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: workspaceSidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: .2)),
        ),
      ),
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 20, 0),
                child: Row(
                  children: [
                    BrandMark(dark: theme.brightness == Brightness.dark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'UniConnect',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WorkspaceNavigation(
                  profileSelected: profileSelected,
                  selectedFeature: selectedFeature,
                  homeEnabled: homeEnabled && !busy,
                  administrator: role == 'SYSTEM_ADMIN' && !busy,
                  onSelect: (value) {
                    if (!busy) onSelect(value);
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.scaffoldBackgroundColor,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      child: Text(
                        name.trim().isEmpty
                            ? '?'
                            : name.trim().characters.first.toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge,
                          ),
                          Text(
                            role == 'ALUMNI'
                                ? 'Alumni'
                                : role == 'SYSTEM_ADMIN'
                                ? 'Administrator'
                                : 'Student',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Log out',
                      onPressed: busy ? null : onLogout,
                      icon: const Icon(Icons.logout, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
