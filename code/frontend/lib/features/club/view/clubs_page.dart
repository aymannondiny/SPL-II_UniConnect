import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../controller/clubs_controller.dart';
import '../data/club_repository.dart';
import '../model/club.dart';
import '../model/club_announcement.dart';
import '../model/club_event.dart';
import '../model/club_creation_request.dart';
import 'widgets/announcement_tile.dart';
import 'widgets/campus_detail_dialog.dart';
import 'widgets/campus_feed_section.dart';
import 'widgets/club_directory.dart';
import 'widgets/club_profile.dart';
import 'widgets/event_details.dart';
import 'widgets/event_tile.dart';

part 'club_request_workflow.dart';
part 'club_request_dialog.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({required this.repository, this.active = true, super.key});
  final ClubRepository repository;
  final bool active;

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  late final ClubsController _controller;
  final _search = TextEditingController();
  List<ClubCreationRequest> _myRequests = [];
  bool _requestLoading = false;
  bool _requestSaving = false;
  String? _requestError;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _controller = ClubsController(widget.repository)..active = widget.active;
    unawaited(_controller.load());
  }

  @override
  void didUpdateWidget(ClubsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _controller.setActive(widget.active);
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  void _update(VoidCallback action) => setState(action);

  void _showClub(Club club) {
    showDialog<void>(
      context: context,
      builder: (_) => CampusDetailDialog<Club>(
        load: () => widget.repository.club(club.id),
        builder: (fresh) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClubProfile(club: fresh),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                _controller.select(fresh);
                Navigator.pop(context);
              },
              child: const Text('Show this club’s updates'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncement(ClubAnnouncement announcement) {
    showDialog<void>(
      context: context,
      builder: (_) => CampusDetailDialog<ClubAnnouncement>(
        load: () => widget.repository.announcement(announcement.id),
        builder: (fresh) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fresh.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(fresh.clubName),
            const SizedBox(height: 16),
            SelectableText(fresh.content),
          ],
        ),
      ),
    );
  }

  void _showEvent(ClubEvent event) {
    showDialog<void>(
      context: context,
      builder: (_) => CampusDetailDialog<ClubEvent>(
        load: () => widget.repository.event(event.id),
        builder: (fresh) => EventDetails(event: fresh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final theme = Theme.of(context);
      final selected = _controller.selected;
      final announcements = CampusFeedSection<ClubAnnouncement>(
        title: 'Announcements',
        feed: _controller.announcements,
        emptyMessage:
            'No announcements right now. Check back for campus updates.',
        itemBuilder: (item) => AnnouncementTile(
          announcement: item,
          onOpen: () => _showAnnouncement(item),
        ),
      );
      final events = CampusFeedSection<ClubEvent>(
        title: _controller.timing == 'PAST' ? 'Past events' : 'Events',
        feed: _controller.events,
        emptyMessage: 'No events match this view. Try another club or timing.',
        itemBuilder: (item) =>
            EventTile(event: item, onOpen: () => _showEvent(item)),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Clubs & events', style: theme.textTheme.headlineMedium),
              OutlinedButton.icon(
                onPressed: _controller.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh campus'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Find your community. Stay close to what’s happening on campus.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          if (widget.repository.session.account?.platformRole == 'STUDENT')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Explore'),
                  selected: _selectedTab == 0,
                  onSelected: (_) => setState(() => _selectedTab = 0),
                ),
                if (widget.repository.session.account?.platformRole ==
                    'STUDENT')
                  ChoiceChip(
                    label: const Text('My requests'),
                    selected: _selectedTab == 2,
                    onSelected: (_) {
                      setState(() => _selectedTab = 2);
                      if (_myRequests.isEmpty && !_requestLoading) {
                        _loadMyRequests();
                      }
                    },
                  ),
              ],
            ),
          const SizedBox(height: 18),
          if (_selectedTab == 2)
            _requestSection()
          else ...[
            ClubDirectory(
              feed: _controller.clubs,
              selectedId: selected?.id,
              onSelect: _showClub,
              onSearch: _controller.searchClubs,
              searchController: _search,
            ),
            const SizedBox(height: 24),
            if (selected != null) ...[
              ClubProfile(club: selected),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: const Text('All clubs'),
                  selected: selected == null,
                  onSelected: (_) => _controller.select(null),
                ),
                if (selected != null) Chip(label: Text(selected.name)),
                for (final filter in [
                  ('ALL', 'All current events'),
                  ('UPCOMING', 'Upcoming'),
                  ('ACTIVE', 'Live now'),
                  if (selected != null) ('PAST', 'Past events'),
                ])
                  ChoiceChip(
                    label: Text(filter.$2),
                    selected: _controller.timing == filter.$1,
                    onSelected: (_) => _controller.filterTiming(filter.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 820
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: announcements),
                        const SizedBox(width: 20),
                        Expanded(child: events),
                      ],
                    )
                  : Column(
                      children: [
                        announcements,
                        const SizedBox(height: 20),
                        events,
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              'Event times use your local timezone. Registration is handled by each organizer.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      );
    },
  );
}
