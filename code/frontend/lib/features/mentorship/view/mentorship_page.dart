import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/view/tabs/mentor_directory_tab.dart';
import 'package:uniconnect/features/mentorship/view/tabs/my_mentorship_tab.dart';
import 'package:uniconnect/features/mentorship/view/tabs/slot_directory_tab.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentor_registration_dialog.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_form_dialog.dart';

class MentorshipPage extends StatefulWidget {
  const MentorshipPage({
    required this.repository,
    required this.session,
    this.active = true,
    super.key,
  });

  final MentorshipRepository repository;
  final SessionController session;
  final bool active;

  @override
  State<MentorshipPage> createState() => _MentorshipPageState();
}

class _MentorshipPageState extends State<MentorshipPage> {
  late final MentorshipController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MentorshipController(widget.repository);
    _controller.loadAll();
  }

  @override
  void didUpdateWidget(covariant MentorshipPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.refreshActiveTab();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final userRole = widget.session.account?.platformRole ?? 'STUDENT';

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _controller.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_controller.error!),
                  backgroundColor: Colors.red.shade800,
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: _controller.clearError,
                  ),
                ),
              );
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peer Mentorship',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect with peer mentors, explore knowledge-sharing sessions, and guide classmates.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  onPressed: _controller.refreshActiveTab,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 10),
                if (_controller.isRegisteredMentor)
                  FilledButton.icon(
                    onPressed: () => MentorshipSlotFormDialog.show(
                      context,
                      controller: _controller,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Host Session'),
                  )
                else if (userRole == 'STUDENT' || userRole == 'ALUMNI')
                  FilledButton.tonalIcon(
                    onPressed: () => MentorRegistrationDialog.show(
                      context,
                      controller: _controller,
                    ),
                    icon: const Icon(Icons.school, size: 18),
                    label: const Text('Become Mentor'),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Navigation Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _tabItem(
                    label: 'Browse Mentors',
                    icon: Icons.people_outline,
                    tab: MentorshipTab.mentors,
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  _tabItem(
                    label: 'Discover Sessions',
                    icon: Icons.calendar_month_outlined,
                    tab: MentorshipTab.slots,
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  _tabItem(
                    label: 'My Mentorship',
                    icon: Icons.person_pin_outlined,
                    tab: MentorshipTab.mySessions,
                    colors: colors,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Content
            switch (_controller.activeTab) {
              MentorshipTab.mentors => MentorDirectoryTab(
                  controller: _controller,
                  repository: widget.repository,
                ),
              MentorshipTab.slots => SlotDirectoryTab(
                  controller: _controller,
                  repository: widget.repository,
                ),
              MentorshipTab.mySessions => MyMentorshipTab(
                  controller: _controller,
                  repository: widget.repository,
                  userRole: userRole,
                ),
            },
          ],
        );
      },
    );
  }

  Widget _tabItem({
    required String label,
    required IconData icon,
    required MentorshipTab tab,
    required ColorScheme colors,
  }) {
    final selected = _controller.activeTab == tab;
    return InkWell(
      onTap: () => _controller.selectTab(tab),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? colors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? colors.primary : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
