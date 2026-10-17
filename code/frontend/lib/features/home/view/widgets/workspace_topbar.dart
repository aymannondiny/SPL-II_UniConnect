import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/authentication/view/widgets/brand_mark.dart';

/// Wireframe search and account tools. Unavailable search is explicit to users.
class WorkspaceTopbar extends StatelessWidget {
  const WorkspaceTopbar({
    required this.compact,
    required this.name,
    required this.busy,
    required this.onProfile,
    required this.onLogout,
    required this.onFeature,
    super.key,
  });
  final bool compact;
  final String name;
  final bool busy;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final ValueChanged<String> onFeature;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
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
                  child: TextField(
                    readOnly: true,
                    onTap: busy ? null : () => onFeature('Search'),
                    decoration: InputDecoration(
                      hintText: compact
                          ? 'Search UniConnect'
                          : 'Search people, clubs, projects',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: dark ? 'Switch to light theme' : 'Switch to dark theme',
              icon: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              onPressed: () {
                ThemePreference.maybeOf(context)?.value = dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
              },
            ),
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
