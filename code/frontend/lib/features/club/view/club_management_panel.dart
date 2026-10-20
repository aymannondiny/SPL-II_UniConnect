import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../data/club_repository.dart';
import '../model/club.dart';
import '../model/club_announcement.dart';
import '../model/club_event.dart';
import '../model/club_page.dart';
import '../model/club_workspace_context.dart';

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
      await widget.repository.selectContext(
        'CLUB',
        assignmentId: widget.clubContext.assignmentId,
      );
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

  Widget _announcementList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _saving ? null : () => _editAnnouncement(),
          icon: const Icon(Icons.add),
          label: const Text('New announcement'),
        ),
      ),
      if (_announcements.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No announcements yet.'),
        )
      else
        for (final item in _announcements)
          Card(
            margin: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Chip(
                        label: Text(item.status),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Text(
                    item.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton.icon(
                        onPressed:
                            _saving ||
                                item.status == 'REMOVED' ||
                                item.status == 'EXPIRED'
                            ? null
                            : () => _editAnnouncement(item: item),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit'),
                      ),
                      if (item.status == 'UNPUBLISHED')
                        FilledButton.icon(
                          onPressed: _saving || _club?.status != 'ACTIVE'
                              ? null
                              : () => _publish(item, 'publish'),
                          icon: const Icon(Icons.publish, size: 17),
                          label: const Text('Publish'),
                        ),
                      if (item.status == 'PUBLISHED')
                        OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => _publish(item, 'unpublish'),
                          child: const Text('Unpublish'),
                        ),
                      if (item.status != 'REMOVED')
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => _publish(item, 'remove'),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ],
  );

  Widget _eventList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _saving || _club?.status != 'ACTIVE'
              ? null
              : () => _editEvent(),
          icon: const Icon(Icons.add),
          label: const Text('New event'),
        ),
      ),
      if (_events.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No events yet.'),
        )
      else
        for (final item in _events)
          Card(
            margin: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Chip(
                        label: Text(item.status),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Text(
                    '${item.startsAt.toLocal()} · ${item.location ?? 'Location to be announced'}',
                  ),
                  if (item.registrationUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Registration link: ${item.registrationUrl}'),
                    ),
                  if (item.registrationDeadline != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Register by ${item.registrationDeadline!.toLocal()}',
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving || item.status == 'REMOVED'
                            ? null
                            : () => _editEvent(item: item),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit'),
                      ),
                      if (item.status != 'REMOVED')
                        TextButton(
                          onPressed: _saving ? null : () => _removeEvent(item),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ],
  );

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

class _ProfileData {
  const _ProfileData(
    this.name,
    this.category,
    this.description,
    this.logoUrl,
    this.contactEmail,
  );
  final String name, category, description;
  final String? logoUrl, contactEmail;
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.club});
  final Club club;
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.club.name);
  late final _category = TextEditingController(text: widget.club.category);
  late final _description = TextEditingController(
    text: widget.club.description,
  );
  late final _logo = TextEditingController(text: widget.club.logoUrl ?? '');
  late final _email = TextEditingController(
    text: widget.club.contactEmail ?? '',
  );
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
    title: const Text('Edit club profile'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Club name'),
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
          Navigator.pop(
            context,
            _ProfileData(
              _name.text.trim(),
              _category.text.trim(),
              _description.text.trim(),
              _logo.text.trim().isEmpty ? null : _logo.text.trim(),
              _email.text.trim().isEmpty ? null : _email.text.trim(),
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _AnnouncementData {
  const _AnnouncementData(
    this.title,
    this.content,
    this.priority,
    this.expiresAt,
    this.publishNow,
  );
  final String title, content, priority;
  final DateTime? expiresAt;
  final bool publishNow;
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog({this.item, required this.canPublish});
  final ClubAnnouncement? item;
  final bool canPublish;
  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  late final _content = TextEditingController(text: widget.item?.content ?? '');
  late final _expiry = TextEditingController(
    text:
        widget.item?.expiresAt?.toLocal().toIso8601String().substring(0, 16) ??
        '',
  );
  late String _priority = widget.item?.priority ?? 'NORMAL';
  bool _publish = false;
  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _expiry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'New announcement' : 'Edit announcement'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: _required,
              ),
              TextFormField(
                controller: _content,
                maxLength: 10000,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(labelText: 'Announcement'),
                validator: _required,
              ),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                  DropdownMenuItem(
                    value: 'IMPORTANT',
                    child: Text('Important'),
                  ),
                  DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                ],
                onChanged: (value) =>
                    setState(() => _priority = value ?? _priority),
              ),
              TextFormField(
                controller: _expiry,
                decoration: const InputDecoration(
                  labelText: 'Expiry (optional)',
                  hintText: 'YYYY-MM-DDTHH:MM',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        DateTime.tryParse(value.trim()) == null
                    ? 'Use YYYY-MM-DDTHH:MM.'
                    : null,
              ),
              if (widget.item == null) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publish immediately'),
                  value: _publish,
                  onChanged: widget.canPublish
                      ? (value) => setState(() => _publish = value)
                      : null,
                ),
                if (!widget.canPublish)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Publishing is paused. This announcement will remain a draft.',
                    ),
                  ),
              ],
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
          final expiry = _expiry.text.trim().isEmpty
              ? null
              : DateTime.parse(_expiry.text.trim());
          Navigator.pop(
            context,
            _AnnouncementData(
              _title.text.trim(),
              _content.text.trim(),
              _priority,
              expiry,
              _publish,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _EventData {
  const _EventData(
    this.title,
    this.description,
    this.location,
    this.registrationUrl,
    this.registrationDeadline,
    this.startsAt,
    this.endsAt,
  );
  final String title, description;
  final String? location, registrationUrl;
  final DateTime? registrationDeadline;
  final DateTime startsAt, endsAt;
}

class _EventDialog extends StatefulWidget {
  const _EventDialog({this.item});
  final ClubEvent? item;
  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  late final _description = TextEditingController(
    text: widget.item?.description ?? '',
  );
  late final _location = TextEditingController(
    text: widget.item?.location ?? '',
  );
  late final _url = TextEditingController(
    text: widget.item?.registrationUrl ?? '',
  );
  late final _deadline = TextEditingController(
    text:
        widget.item?.registrationDeadline
            ?.toLocal()
            .toIso8601String()
            .substring(0, 16) ??
        '',
  );
  late final _starts = TextEditingController(
    text: _dateInput(widget.item?.startsAt),
  );
  late final _ends = TextEditingController(
    text: _dateInput(widget.item?.endsAt),
  );
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _url.dispose();
    _deadline.dispose();
    _starts.dispose();
    _ends.dispose();
    super.dispose();
  }

  static String _dateInput(DateTime? date) =>
      date?.toLocal().toIso8601String().substring(0, 16) ?? '';
  String? _validateDate(String? value) =>
      DateTime.tryParse(value?.trim() ?? '') == null
      ? 'Use YYYY-MM-DDTHH:MM.'
      : null;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'New event' : 'Edit event'),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Event title'),
                validator: _required,
              ),
              TextFormField(
                controller: _description,
                maxLength: 10000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _required,
              ),
              TextFormField(
                controller: _location,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                ),
              ),
              TextFormField(
                controller: _starts,
                decoration: const InputDecoration(
                  labelText: 'Starts at',
                  hintText: 'YYYY-MM-DDTHH:MM',
                ),
                validator: _validateDate,
              ),
              TextFormField(
                controller: _ends,
                decoration: const InputDecoration(
                  labelText: 'Ends at',
                  hintText: 'YYYY-MM-DDTHH:MM',
                ),
                validator: _validateDate,
              ),
              TextFormField(
                controller: _url,
                maxLength: 2048,
                decoration: const InputDecoration(
                  labelText: 'External registration URL (optional)',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        Uri.tryParse(value.trim())?.scheme != 'https'
                    ? 'Use an HTTPS URL.'
                    : null,
              ),
              TextFormField(
                controller: _deadline,
                decoration: const InputDecoration(
                  labelText: 'Registration deadline (optional)',
                  hintText: 'YYYY-MM-DDTHH:MM',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        DateTime.tryParse(value.trim()) == null
                    ? 'Use YYYY-MM-DDTHH:MM.'
                    : null,
              ),
              Text(
                'Time is entered in your local timezone and saved using UniConnect’s UTC convention.',
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
          final starts = DateTime.parse(_starts.text.trim());
          final ends = DateTime.parse(_ends.text.trim());
          if (!ends.isAfter(starts)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End time must be after start time.'),
              ),
            );
            return;
          }
          final deadline = _deadline.text.trim().isEmpty
              ? null
              : DateTime.parse(_deadline.text.trim());
          Navigator.pop(
            context,
            _EventData(
              _title.text.trim(),
              _description.text.trim(),
              _location.text.trim().isEmpty ? null : _location.text.trim(),
              _url.text.trim().isEmpty ? null : _url.text.trim(),
              deadline,
              starts,
              ends,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required.' : null;
