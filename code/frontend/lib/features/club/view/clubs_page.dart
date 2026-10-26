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
import '../model/club_workspace_context.dart';
import 'club_management_panel.dart';
import 'widgets/announcement_tile.dart';
import 'widgets/campus_detail_dialog.dart';
import 'widgets/campus_feed_section.dart';
import 'widgets/club_directory.dart';
import 'widgets/club_profile.dart';
import 'widgets/event_details.dart';
import 'widgets/event_tile.dart';

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
  List<ClubWorkspaceContext> _managerContexts = [];
  List<ClubCreationRequest> _myRequests = [];
  bool _requestLoading = false;
  bool _requestSaving = false;
  String? _requestError;
  int _selectedTab = 0;
  int _selectedManager = 0;

  @override
  void initState() {
    super.initState();
    _controller = ClubsController(widget.repository)..active = widget.active;
    unawaited(_controller.load());
    unawaited(_loadWorkspaceContexts());
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

  Future<void> _loadWorkspaceContexts() async {
    try {
      final contexts = await widget.repository.contexts();
      if (!mounted) return;
      setState(() {
        _managerContexts = contexts
            .where(
              (value) =>
                  value.contextType == 'CLUB' &&
                  value.clubRole == 'CLUB_ADMINISTRATOR' &&
                  value.assignmentId != null &&
                  value.clubId != null,
            )
            .toList();
        if (_selectedManager >= _managerContexts.length) _selectedManager = 0;
        if (_selectedTab == 1 && _managerContexts.isEmpty) _selectedTab = 0;
      });
    } on Object {
      // Public club discovery remains available if the optional role context cannot load.
    }
  }

  Future<void> _loadMyRequests() async {
    setState(() {
      _requestLoading = true;
      _requestError = null;
    });
    try {
      final requests = await widget.repository.myRequests();
      if (!mounted) return;
      setState(() {
        _myRequests = requests;
        _requestLoading = false;
      });
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() {
          _requestError = failure.message;
          _requestLoading = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _requestError = 'Unable to load your club requests. Please retry.';
          _requestLoading = false;
        });
      }
    }
  }

  Future<void> _requestClub() async {
    final values = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => const _ClubRequestDialog(),
    );
    if (values == null || !mounted) return;
    setState(() => _requestSaving = true);
    try {
      await widget.repository.submitRequest(
        name: values['name']!,
        category: values['category']!,
        description: values['description']!,
        logoUrl: values['logo'],
        contactEmail: values['email'],
      );
      await _loadMyRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club request submitted for review.')),
        );
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to submit your request. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _requestSaving = false);
    }
  }

  Widget _requestSection() => SectionCard(
    title: 'My club creation requests',
    subtitle: 'Requests are reviewed by a system administrator. If approved, you become an administrator of the new club.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _requestLoading ? null : _loadMyRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh requests'),
            ),
            FilledButton.icon(
              onPressed: _requestSaving ? null : _requestClub,
              icon: const Icon(Icons.add),
              label: const Text('Request a club'),
            ),
          ],
        ),
        if (_requestSaving) const LinearProgressIndicator(minHeight: 2),
        if (_requestLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_requestError != null)
          Column(
            children: [
              Text(_requestError!, textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: _loadMyRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          )
        else if (_myRequests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('You have not requested a club yet.'),
          )
        else
          for (final request in _myRequests)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
              title: Text(request.clubName),
              subtitle: Text(
                '${request.category} · Submitted ${request.createdAt.toLocal().toString().split('.').first}',
              ),
              trailing: Chip(
                label: Text(request.status),
                visualDensity: VisualDensity.compact,
              ),
            ),
      ],
    ),
  );

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
          if (widget.repository.session.account?.platformRole == 'STUDENT' ||
              _managerContexts.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Explore'),
                  selected: _selectedTab == 0,
                  onSelected: (_) => setState(() => _selectedTab = 0),
                ),
                if (_managerContexts.isNotEmpty)
                  ChoiceChip(
                    label: const Text('Manage clubs'),
                    selected: _selectedTab == 1,
                    onSelected: (_) => setState(() => _selectedTab = 1),
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
          if (_selectedTab == 1 && _managerContexts.isNotEmpty) ...[
            Text(
              'Club you manage',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _managerContexts[_selectedManager].assignmentId,
              decoration: const InputDecoration(),
              items: [
                for (final item in _managerContexts)
                  DropdownMenuItem(
                    value: item.assignmentId,
                    child: Text(item.clubName ?? 'Club ${item.clubId}'),
                  ),
              ],
              onChanged: (assignment) {
                if (assignment == null) return;
                setState(
                  () => _selectedManager = _managerContexts.indexWhere(
                    (value) => value.assignmentId == assignment,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ClubManagementPanel(
              key: ValueKey(_managerContexts[_selectedManager].assignmentId),
              repository: widget.repository,
              clubContext: _managerContexts[_selectedManager],
            ),
          ] else if (_selectedTab == 2)
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

class _ClubRequestDialog extends StatefulWidget {
  const _ClubRequestDialog();
  @override
  State<_ClubRequestDialog> createState() => _ClubRequestDialogState();
}

class _ClubRequestDialogState extends State<_ClubRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _logo = TextEditingController();
  final _email = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _logo.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required.' : null;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Request a new club'),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Proposed club name',
                ),
                validator: _required,
              ),
              TextFormField(
                controller: _category,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: _required,
              ),
              TextFormField(
                controller: _description,
                maxLength: 5000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _required,
              ),
              TextFormField(
                controller: _logo,
                maxLength: 2048,
                decoration: const InputDecoration(
                  labelText: 'Logo URL (optional)',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        Uri.tryParse(value.trim())?.scheme != 'https'
                    ? 'Use an HTTPS URL.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Contact email (optional)',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        !value.contains('@')
                    ? 'Enter a valid email.'
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                'A system administrator reviews the proposal. Club administrator access begins only after approval.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!(_form.currentState?.validate() ?? false)) return;
          Navigator.pop(context, <String, String?>{
            'name': _name.text.trim(),
            'category': _category.text.trim(),
            'description': _description.text.trim(),
            'logo': _logo.text.trim().isEmpty ? null : _logo.text.trim(),
            'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
          });
        },
        child: const Text('Submit request'),
      ),
    ],
  );
}
