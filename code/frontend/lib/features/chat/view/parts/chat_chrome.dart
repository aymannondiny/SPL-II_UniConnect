part of '../chat_page.dart';

extension _ChatChrome on _ChatPageState {
  Widget _sidebar() {
    final account = widget.sessionController.account;
    return WorkspaceSidebar(
      name: account?.fullName ?? 'Your account',
      role: account?.platformRole ?? 'STUDENT',
      profileSelected: false,
      selectedFeature: 'Messages',
      homeEnabled: true,
      busy: widget.sessionController.busy,
      onSelect: (feature) {
        if (feature == 'Messages') {
          _update(() => _showThread = false);
        } else {
          _openWorkspaceFeature(feature);
        }
      },
      onLogout: widget.sessionController.logout,
    );
  }

  Widget _topBar({required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget actionButton({
      required String tooltip,
      required IconData icon,
      required VoidCallback onPressed,
      Widget? child,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        backgroundColor: colors.surface.withValues(alpha: .7),
        foregroundColor: colors.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: child ?? Icon(icon, size: 23),
    );

    return Container(
      height: 88,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 30),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF022318) : const Color(0xFFF8F3F2),
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: .35),
          ),
        ),
      ),
      child: Row(
        children: [
          if (compact)
            IconButton(
              tooltip: 'Back to inbox',
              onPressed: () => _update(() => _showThread = false),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          Flexible(
            fit: FlexFit.loose,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: TextField(
                controller: _search,
                onChanged: (_) => _update(() {}),
                decoration: InputDecoration(
                  hintText: 'Search people, clubs, projects',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 17),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: .3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            _update(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
          ),
          if (!compact) const Spacer(),
          actionButton(
            tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            onPressed: _toggleTheme,
          ),
          const SizedBox(width: 12),
          actionButton(
            tooltip: 'Notifications',
            icon: Icons.notifications_none,
            onPressed: () => _openWorkspaceFeature('Notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, size: 23),
                Positioned(
                  right: -9,
                  top: -10,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '4',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            actionButton(
              tooltip: 'Profile',
              icon: Icons.person_outline,
              onPressed: () => _openWorkspaceFeature('My profile'),
            ),
          ],
        ],
      ),
    );
  }
}
