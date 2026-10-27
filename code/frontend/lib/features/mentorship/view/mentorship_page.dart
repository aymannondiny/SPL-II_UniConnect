import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/model/mentor_eligibility.dart';
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
    this.yearOfStudy,
    super.key,
  });

  final MentorshipRepository repository;
  final SessionController session;
  final bool active;
  final int? yearOfStudy;

  @override
  State<MentorshipPage> createState() => _MentorshipPageState();
}

class _MentorshipPageState extends State<MentorshipPage> {
  late final MentorshipController _controller;
  String? _displayedError;

  @override
  void initState() {
    super.initState();
    _controller = MentorshipController(widget.repository);
    _controller.addListener(_onControllerChange);
    _controller.loadAll();
  }

  void _onControllerChange() {
    if (!mounted) return;
    final err = _controller.error;
    if (err == _displayedError) return;
    _displayedError = err;
    if (err == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: _controller.clearError,
          ),
        ),
      );
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
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRole = widget.session.account?.platformRole ?? 'STUDENT';

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(theme, userRole),
            if (!_controller.isRegisteredMentor &&
                MentorEligibility(
                      role: userRole,
                      yearOfStudy: widget.yearOfStudy,
                    ).explanation !=
                    null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  MentorEligibility(
                    role: userRole,
                    yearOfStudy: widget.yearOfStudy,
                  ).explanation!,
                ),
              ),
            const SizedBox(height: 22),
            _tabBar(theme),
            const SizedBox(height: 18),

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
                yearOfStudy: widget.yearOfStudy,
              ),
            },
          ],
        );
      },
    );
  }

  Widget _pageHeader(ThemeData theme, String userRole) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      final actions = Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          if (_controller.isRegisteredMentor)
            FilledButton.icon(
              onPressed: () => MentorshipSlotFormDialog.show(
                context,
                controller: _controller,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Host Session'),
            )
          else if (MentorEligibility(
            role: userRole,
            yearOfStudy: widget.yearOfStudy,
          ).canRegister)
            FilledButton.tonalIcon(
              onPressed: () => MentorRegistrationDialog.show(
                context,
                controller: _controller,
              ),
              icon: const Icon(Icons.school, size: 18),
              label: const Text('Become Mentor'),
            ),
        ],
      );

      final title = Text(
        'Peer Mentorship',
        style: theme.textTheme.headlineMedium,
      );
      final description = Text(
        'Connect with peer mentors, explore knowledge-sharing sessions, and guide classmates.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
      final refresh = IconButton.outlined(
        onPressed: _controller.refreshActiveTab,
        icon: const Icon(Icons.refresh, size: 19),
        tooltip: 'Refresh',
      );

      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: title),
                refresh,
              ],
            ),
            const SizedBox(height: 4),
            description,
            if (actions.children.isNotEmpty) ...[
              const SizedBox(height: 14),
              actions,
            ],
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 5), description],
            ),
          ),
          refresh,
          if (actions.children.isNotEmpty) ...[
            const SizedBox(width: 10),
            actions,
          ],
        ],
      );
    },
  );

  Widget _tabBar(ThemeData theme) => Container(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
        ),
      ),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabItem(
            label: 'Browse Mentors',
            icon: Icons.people_outline,
            tab: MentorshipTab.mentors,
            count: _controller.totalMentors,
            theme: theme,
          ),
          _tabItem(
            label: 'Discover Sessions',
            icon: Icons.calendar_month_outlined,
            tab: MentorshipTab.slots,
            count: _controller.totalSlots,
            theme: theme,
          ),
          _tabItem(
            label: 'My Mentorship',
            icon: Icons.person_pin_outlined,
            tab: MentorshipTab.mySessions,
            count:
                _controller.myEnrolledSlots.length +
                _controller.myMentoringSlots.length,
            theme: theme,
          ),
        ],
      ),
    ),
  );

  Widget _tabItem({
    required String label,
    required IconData icon,
    required MentorshipTab tab,
    required int count,
    required ThemeData theme,
  }) {
    final selected = _controller.activeTab == tab;
    final colors = theme.colorScheme;
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
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? colors.onSurface : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: .12)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
