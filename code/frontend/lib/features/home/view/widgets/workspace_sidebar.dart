import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/authentication/view/widgets/brand_mark.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_dimensions.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_navigation.dart';
import 'package:uniconnect/features/home/view/widgets/engineering_decorations.dart';

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({
    required this.name,
    required this.role,
    this.access,
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
  final WorkspaceAccess? access;
  final bool profileSelected;
  final String? selectedFeature;
  final bool homeEnabled;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engineering = EngineeringTheme.active(context);
    return Container(
      width: workspaceSidebarWidth,
      decoration: BoxDecoration(
        color: engineering ? null : theme.colorScheme.surface,
        gradient: engineering
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A0811),
                  Color(0xFF12080E),
                  Color(0xFF180713),
                ],
                stops: [0, .6, 1],
              )
            : null,
        borderRadius: engineering
            ? const BorderRadius.horizontal(right: Radius.circular(20))
            : null,
        border: Border(
          right: BorderSide(
            color: engineering
                ? const Color(0xFF4D2031)
                : theme.dividerColor.withValues(alpha: .2),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  engineering ? 30 : 24,
                  engineering ? 24 : 22,
                  20,
                  0,
                ),
                child: Row(
                  children: [
                    if (engineering)
                      const EngineeringBrandMark()
                    else
                      BrandMark(dark: theme.brightness == Brightness.dark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UniConnect',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (engineering)
                            const Text(
                              'IUT COMMUNITY PLATFORM',
                              style: TextStyle(
                                color: Color(0xFFDCC5CD),
                                fontSize: 8,
                                letterSpacing: 1.1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WorkspaceNavigation(
                  access: access,
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
                margin: EdgeInsets.fromLTRB(14, 8, 14, engineering ? 10 : 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: engineering
                      ? Colors.transparent
                      : theme.scaffoldBackgroundColor,
                  border: engineering
                      ? const Border(top: BorderSide(color: Color(0xFF572235)))
                      : null,
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
                    if (!engineering)
                      IconButton(
                        tooltip: 'Log out',
                        onPressed: busy ? null : onLogout,
                        icon: const Icon(Icons.logout, size: 20),
                      ),
                  ],
                ),
              ),
              if (engineering) const EngineeringSidebarBlueprint(),
            ],
          ),
        ),
      ),
    );
  }
}
