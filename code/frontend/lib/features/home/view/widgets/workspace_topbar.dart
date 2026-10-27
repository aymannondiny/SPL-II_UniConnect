import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/appearance_menu_button.dart';
import 'package:uniconnect/features/authentication/view/widgets/brand_mark.dart';

/// Workspace tools with a shortcut to the member directory.
class WorkspaceTopbar extends StatelessWidget {
  const WorkspaceTopbar({
    required this.compact,
    required this.name,
    required this.busy,
    required this.onProfile,
    required this.onLogout,
    required this.onFeature,
    this.contextSwitcher,
    this.discoveryEnabled = true,
    this.engineeringSearchTarget,
    this.engineeringSearchHint,
    super.key,
  });
  final bool compact;
  final bool discoveryEnabled;
  final String name;
  final bool busy;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final ValueChanged<String> onFeature;
  final Widget? contextSwitcher;
  final String? engineeringSearchTarget;
  final String? engineeringSearchHint;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    if (!compact && EngineeringTheme.active(context)) {
      return _EngineeringTopbar(
        name: name,
        busy: busy,
        onProfile: onProfile,
        onFeature: onFeature,
        discoveryEnabled: discoveryEnabled,
        contextSwitcher: contextSwitcher,
        searchTarget: engineeringSearchTarget,
        searchHint: engineeringSearchHint,
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 32,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: .2)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (compact) ...[BrandMark(dark: dark), const SizedBox(width: 8)],
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: discoveryEnabled
                      ? TextField(
                          readOnly: true,
                          onTap: busy ? null : () => onFeature('Search'),
                          decoration: InputDecoration(
                            hintText: compact
                                ? 'Find people'
                                : 'Find students and alumni',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        )
                      : Text(
                          'UniConnect workspace',
                          style: theme.textTheme.titleMedium,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const AppearanceMenuButton(),
            if (!compact) ...[
              IconButton(
                tooltip: 'Notifications',
                onPressed: busy ? null : () => onFeature('Notifications'),
                icon: const Icon(Icons.notifications_none),
              ),
              IconButton(
                tooltip: 'My profile',
                onPressed: busy ? null : onProfile,
                icon: const Icon(Icons.person_outline),
              ),
            ],
            PopupMenuButton<String>(
              tooltip: 'Account menu',
              onSelected: (value) {
                if (value == 'profile') {
                  onProfile();
                } else {
                  onLogout();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(name)),
                PopupMenuItem(
                  value: 'profile',
                  enabled: !busy,
                  child: const Text('My profile'),
                ),
                PopupMenuItem(
                  value: 'logout',
                  enabled: !busy,
                  child: const Text('Log out'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineeringTopbar extends StatelessWidget {
  const _EngineeringTopbar({
    required this.name,
    required this.busy,
    required this.onProfile,
    required this.onFeature,
    required this.discoveryEnabled,
    this.searchTarget,
    this.searchHint,
    this.contextSwitcher,
  });

  final String name;
  final bool busy;
  final VoidCallback onProfile;
  final ValueChanged<String> onFeature;
  final bool discoveryEnabled;
  final Widget? contextSwitcher;
  final String? searchTarget;
  final String? searchHint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final showContext =
          contextSwitcher != null && constraints.maxWidth >= 1080;
      final target = searchTarget ?? (discoveryEnabled ? 'Search' : null);
      final showSearch = target != null && constraints.maxWidth >= 700;
      return Padding(
        padding: const EdgeInsets.fromLTRB(38, 18, 28, 0),
        child: Row(
          key: const Key('engineering-topbar'),
          children: [
            if (showContext) ...[SizedBox(width: 210, child: contextSwitcher)],
            const Spacer(),
            if (showSearch) ...[
              const SizedBox(width: 22),
              SizedBox(
                width: constraints.maxWidth >= 1120 ? 520 : 340,
                height: 44,
                child: TextField(
                  readOnly: true,
                  onTap: busy ? null : () => onFeature(target),
                  decoration: InputDecoration(
                    hintText: searchHint ?? 'Search UniConnect...',
                    prefixIcon: const Icon(Icons.search, size: 21),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            const AppearanceMenuButton(compact: true),
            IconButton(
              tooltip: 'Notifications',
              onPressed: busy ? null : () => onFeature('Notifications'),
              icon: const Badge(child: Icon(Icons.notifications_none)),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: 'My profile',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: busy ? null : onProfile,
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFF7E2848),
                  foregroundColor: Colors.white,
                  child: Text(
                    name.trim().isEmpty
                        ? '?'
                        : name.trim().characters.first.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
