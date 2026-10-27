import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../data/club_repository.dart';
import '../model/club.dart';
import '../model/club_announcement.dart';
import '../model/club_event.dart';
import '../model/club_page.dart';
import '../model/club_workspace_context.dart';

part 'club_profile_dialog.dart';
part 'club_announcement_dialog.dart';
part 'club_event_dialog.dart';
part 'club_publication_lists.dart';

class ClubManagementPanel extends StatefulWidget {
  const ClubManagementPanel({
    required this.repository,
    required this.clubContext,
    super.key,
  });
  final ClubRepository repository;
  final ClubWorkspaceContext clubContext;
  @override
  State<ClubManagementPanel> createState() => _ClubManagementPanelState();
}

class _ClubManagementPanelState extends State<ClubManagementPanel> {
  Club? _club;
  List<ClubAnnouncement> _announcements = [];
  List<ClubEvent> _events = [];
  int _section = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int get _clubId => widget.clubContext.clubId!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.club(_clubId),
        widget.repository.managedAnnouncements(_clubId),
        widget.repository.managedEvents(_clubId),
      ]);
      if (!mounted) return;
      setState(() {
        _club = results[0] as Club;
        _announcements = (results[1] as ClubPage<ClubAnnouncement>).items;
        _events = (results[2] as ClubPage<ClubEvent>).items;
        _loading = false;
      });
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _loading = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _error = 'Unable to load club management. Please retry.';
          _loading = false;
        });
      }
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  Future<String?> _reason(String title, String prompt) => showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );

  Future<void> _editProfile() async {
    final club = _club;
    if (club == null) return;
    final result = await showDialog<_ProfileData>(
      context: context,
      builder: (_) => _ProfileDialog(club: club),
    );
    if (result == null || !mounted) return;
    await _perform(
      () => widget.repository.saveProfile(
        _clubId,
        name: result.name,
        category: result.category,
        description: result.description,
        logoUrl: result.logoUrl,
        contactEmail: result.contactEmail,
      ),
      'Club profile updated.',
    );
  }

  Future<void> _editAnnouncement({ClubAnnouncement? item}) async {
    final result = await showDialog<_AnnouncementData>(
      context: context,
      builder: (_) => _AnnouncementDialog(
        item: item,
        canPublish: _club?.status == 'ACTIVE',
      ),
    );
    if (result == null || !mounted) return;
    await _perform(
      () => widget.repository.saveAnnouncement(
        _clubId,
        id: item?.id,
        title: result.title,
        content: result.content,
        priority: result.priority,
        expiresAt: result.expiresAt,
        publishNow: result.publishNow,
      ),
      item == null
          ? (result.publishNow ? 'Announcement published.' : 'Draft saved.')
          : 'Announcement updated.',
    );
  }

  Future<void> _editEvent({ClubEvent? item}) async {
    final result = await showDialog<_EventData>(
      context: context,
      builder: (_) => _EventDialog(item: item),
    );
    if (result == null || !mounted) return;
    await _perform(
      () => widget.repository.saveEvent(
        _clubId,
        id: item?.id,
        title: result.title,
        description: result.description,
        location: result.location,
        registrationUrl: result.registrationUrl,
        registrationDeadline: result.registrationDeadline,
        startsAt: result.startsAt,
        endsAt: result.endsAt,
      ),
      item == null ? 'Event created.' : 'Event updated.',
    );
  }

  Future<void> _publish(ClubAnnouncement item, String action) async {
    if (action == 'publish') {
      await _perform(
        () => widget.repository.publishAnnouncement(_clubId, item.id),
        'Announcement published.',
      );
      return;
    }
    final reason = await _reason(
      action == 'unpublish' ? 'Unpublish announcement' : 'Remove announcement',
      'This action will change the status of “${item.title}”.',
    );
    if (reason == null || !mounted) return;
    await _perform(
      () => action == 'unpublish'
          ? widget.repository.unpublishAnnouncement(_clubId, item.id, reason)
          : widget.repository.removeAnnouncement(_clubId, item.id, reason),
      action == 'unpublish'
          ? 'Announcement unpublished.'
          : 'Announcement removed.',
    );
  }

  Future<void> _removeEvent(ClubEvent item) async {
    final reason = await _reason(
      'Remove event',
      'Remove “${item.title}” from active event listings?',
    );
    if (reason == null || !mounted) return;
    await _perform(
      () => widget.repository.removeEvent(_clubId, item.id, reason),
      'Event removed.',
    );
  }

  Future<void> _perform(Future<void> Function() action, String success) async {
    setState(() => _saving = true);
    try {
      await action();
      await _load();
      if (mounted) _message(success);
    } on AuthFailure catch (failure) {
      if (mounted) _message(failure.message);
    } on Object {
      if (mounted) _message('Unable to save these changes. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = _club;
    return SectionCard(
      title: 'Manage ${widget.clubContext.clubName ?? 'your club'}',
      subtitle: 'Update the shared club profile, announcements and events.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            )
          else if (club != null) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${club.category} · ${club.status.replaceAll('_', ' ').toLowerCase()}',
                        ),
                      ],
                    ),
                    if (widget.clubContext.clubRole == 'CLUB_ADMINISTRATOR')
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _editProfile,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit profile'),
                      ),
                  ],
                ),
              ),
            ),
            if (club.status == 'PUBLISHING_SUSPENDED')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Publishing is paused by a system administrator. You can save announcement drafts and edit existing content, while publishing and new event creation are unavailable.',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Announcements')),
                ButtonSegment(value: 1, label: Text('Events')),
              ],
              selected: {_section},
              onSelectionChanged: (value) =>
                  setState(() => _section = value.first),
            ),
            if (_saving) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 10),
            _section == 0 ? _announcementList() : _eventList(),
            Text(
              'Event registration links are external. UniConnect does not register attendees through these links.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
