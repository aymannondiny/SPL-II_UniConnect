import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/administration/data/admin_club_repository.dart';
import 'package:uniconnect/features/administration/model/club_administration_entry.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/club/model/club.dart';
import 'package:uniconnect/features/club/model/club_creation_request.dart';

class AdminClubWorkspace extends StatefulWidget {
  const AdminClubWorkspace({required this.repository, super.key});
  final AdminClubRepository repository;
  @override
  State<AdminClubWorkspace> createState() => _AdminClubWorkspaceState();
}

class _AdminClubWorkspaceState extends State<AdminClubWorkspace> {
  List<ClubAdministrationEntry> _clubs = [];
  final _search = TextEditingController();
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _clubs = [];
    });
    try {
      final page = reset ? 0 : _page + 1;
      final result = await widget.repository.clubs(
        search: _search.text.trim(),
        page: page,
      );
      if (!mounted) return;
      setState(() {
        _clubs = [..._clubs, ...result.items];
        _page = page;
        _hasMore = (page + 1) * 50 < result.total;
        _loading = false;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = failure.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load clubs. Please retry.';
        _loading = false;
      });
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  Future<void> _edit({Club? club}) async {
    final result = await showDialog<_ClubFormData>(
      context: context,
      builder: (_) =>
          _ClubEditorDialog(repository: widget.repository, club: club),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (club == null) {
        await widget.repository.createClub(
          name: result.name,
          category: result.category,
          description: result.description,
          administratorIds: result.administratorIds,
          logoUrl: result.logoUrl,
          contactEmail: result.contactEmail,
        );
      } else {
        await widget.repository.editClub(
          club.id,
          name: result.name,
          category: result.category,
          description: result.description,
          logoUrl: result.logoUrl,
          contactEmail: result.contactEmail,
        );
      }
      await _load();
      if (mounted) {
        _message(club == null ? 'Club created.' : 'Club profile saved.');
      }
    } on AuthFailure catch (failure) {
      if (mounted) _message(failure.message);
    } on Object {
      if (mounted) _message('Unable to save this club. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _reasonDialog(String title, String prompt) =>
      showDialog<String>(
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
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Add a short explanation',
                  ),
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
                  if (controller.text.trim().isEmpty) return;
                  Navigator.pop(dialogContext, controller.text.trim());
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

  Future<void> _assign(ClubAdministrationEntry entry) async {
    final userId = await showDialog<int>(
      context: context,
      builder: (_) => _AssignAdministratorDialog(
        repository: widget.repository,
        entry: entry,
      ),
    );
    if (userId == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.repository.assignAdministrator(entry.club.id, userId);
      await _load();
      if (mounted) _message('Club administrator assigned.');
    } on AuthFailure catch (failure) {
      if (mounted) _message(failure.message);
    } on Object {
      if (mounted) _message('Unable to assign this student. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(
    ClubAdministrationEntry entry,
    ClubAdministratorAssignment administrator,
  ) async {
    final reason = await _reasonDialog(
      'Remove administrator',
      'Remove ${administrator.fullName} from ${entry.club.name}? Other administrators keep their access.',
    );
    if (reason == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.repository.removeAdministrator(
        entry.club.id,
        administrator.id,
        reason,
      );
      await _load();
      if (mounted) _message('Administrator assignment removed.');
    } on AuthFailure catch (failure) {
      if (mounted) _message(failure.message);
    } on Object {
      if (mounted) {
        _message('Unable to remove this administrator. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _lifecycle(Club club, String action, String label) async {
    final reason = await _reasonDialog(label, switch (action) {
      'archive/restore' =>
        'Restore ${club.name} to its status before it was archived. An eligible current student administrator must be assigned.',
      'archive' =>
        'Archive ${club.name}. It will leave public club listings but can be restored later.',
      'delete' =>
        'Delete ${club.name}. It will be removed from the administration list and cannot be restored.',
      _ => 'This change affects ${club.name} and its publishing access.',
    });
    if (reason == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.repository.lifecycle(club.id, action, reason);
      await _load();
      if (mounted) _message('$label completed.');
    } on AuthFailure catch (failure) {
      if (mounted) _message(failure.message);
    } on Object {
      if (mounted) _message('Unable to update this club. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _clubCard(ClubAdministrationEntry entry) {
    final club = entry.club;
    final archived = club.status == 'ARCHIVED';
    final suspended = club.status == 'PUBLISHING_SUSPENDED';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary
                          .withValues(alpha: .12),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.groups_outlined),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          club.category,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        archived
                            ? 'Archived'
                            : suspended
                            ? 'Publishing paused'
                            : 'Active',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    PopupMenuButton<String>(
                      enabled: !_saving,
                      tooltip: 'Club actions',
                      onSelected: (action) => switch (action) {
                        'restoreArchive' => _lifecycle(
                          club,
                          'archive/restore',
                          'Restore club',
                        ),
                        'edit' => _edit(club: club),
                        'pause' => _lifecycle(
                          club,
                          'publishing/suspend',
                          'Pause publishing',
                        ),
                        'restore' => _lifecycle(
                          club,
                          'publishing/restore',
                          'Restore publishing',
                        ),
                        'archive' => _lifecycle(
                          club,
                          'archive',
                          'Archive club',
                        ),
                        _ => _lifecycle(club, 'delete', 'Delete club'),
                      },
                      itemBuilder: (_) => archived
                          ? [
                              const PopupMenuItem(
                                value: 'restoreArchive',
                                child: Text('Restore archived club'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete club'),
                              ),
                            ]
                          : [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit club profile'),
                              ),
                              if (suspended)
                                const PopupMenuItem(
                                  value: 'restore',
                                  child: Text('Restore publishing'),
                                )
                              else
                                const PopupMenuItem(
                                  value: 'pause',
                                  child: Text('Pause publishing'),
                                ),
                              const PopupMenuItem(
                                value: 'archive',
                                child: Text('Archive club'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete club'),
                              ),
                            ],
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.more_horiz),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              club.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Club administrators',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _assign(entry),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: Text(archived ? 'Add before restore' : 'Add'),
                ),
              ],
            ),
            if (entry.administrators.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No current administrators.'),
              )
            else
              for (final admin in entry.administrators)
                if (admin.current)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const CircleAvatar(
                      radius: 17,
                      child: Icon(Icons.person_outline, size: 18),
                    ),
                    title: Text(admin.fullName),
                    subtitle: Text('Student account · ${admin.userId}'),
                    trailing:
                        !archived &&
                            entry.administrators
                                    .where((value) => value.current)
                                    .length >
                                1
                        ? IconButton(
                            tooltip: 'Remove assignment',
                            onPressed: _saving
                                ? null
                                : () => _remove(entry, admin),
                            icon: const Icon(Icons.person_remove_outlined),
                          )
                        : null,
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Club administration',
    subtitle: 'Create clubs, manage publishing and keep multiple administrators assigned to each club.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _search,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  labelText: 'Search clubs',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    onPressed: _load,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create club'),
                ),
              ],
            ),
          ],
        ),
        if (_saving) const LinearProgressIndicator(minHeight: 2),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _EmptyClubAdmin(
            message: _error!,
            action: TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          )
        else if (_clubs.isEmpty)
          const _EmptyClubAdmin(message: 'No clubs have been created yet.')
        else ...[
          for (var i = 0; i < _clubs.length; i++) ...[
            _clubCard(_clubs[i]),
            if (i != _clubs.length - 1) const SizedBox(height: 12),
          ],
        ],
        if (_hasMore && !_loading)
          Center(
            child: TextButton.icon(
              onPressed: () => _load(reset: false),
              icon: const Icon(Icons.expand_more),
              label: const Text('Load more clubs'),
            ),
          ),
      ],
    ),
  );
}

class AdminClubRequests extends StatefulWidget {
  const AdminClubRequests({required this.repository, super.key});
  final AdminClubRepository repository;
  @override
  State<AdminClubRequests> createState() => _AdminClubRequestsState();
}

class _AdminClubRequestsState extends State<AdminClubRequests> {
  List<ClubCreationRequest> _requests = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _tab = 0;
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
      final requests = await widget.repository.requests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
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
          _error = 'Unable to load club requests. Please retry.';
          _loading = false;
        });
      }
    }
  }

  Future<String?> _reason(ClubCreationRequest request) => showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      return AlertDialog(
        title: const Text('Reject club request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${request.clubName} requested by ${request.requesterName ?? 'student'}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      );
    },
  );
  Future<void> _decide(ClubCreationRequest request, bool approve) async {
    String? reason;
    if (!approve) {
      reason = await _reason(request);
      if (reason == null || !mounted) return;
    } else {
      final yes = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Approve club request'),
          content: Text(
            'Create ${request.clubName} and assign ${request.requesterName ?? 'the requester'} as its club administrator?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.decideRequest(
        request.id,
        approve: approve,
        reason: reason,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Club request approved. The requester is an administrator now.'
                  : 'Club request rejected.',
            ),
          ),
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
          const SnackBar(content: Text('Unable to update this request.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _requests
        .where(
          (request) => _tab == 0
              ? request.status == 'PENDING'
              : request.status != 'PENDING',
        )
        .toList();
    return SectionCard(
      title: 'Club creation requests',
      subtitle: 'Review student proposals and track decisions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Pending')),
                  ButtonSegment(value: 1, label: Text('Processed history')),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          if (_saving) const LinearProgressIndicator(minHeight: 2),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _EmptyClubAdmin(
              message: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            )
          else if (visible.isEmpty)
            _EmptyClubAdmin(
              message: _tab == 0
                  ? 'There are no pending club requests.'
                  : 'Processed requests will appear here.',
            )
          else
            for (var i = 0; i < visible.length; i++) ...[
              _RequestCard(
                request: visible[i],
                saving: _saving,
                onApprove: () => _decide(visible[i], true),
                onReject: () => _decide(visible[i], false),
              ),
              if (i != visible.length - 1) const Divider(height: 20),
            ],
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.saving,
    required this.onApprove,
    required this.onReject,
  });
  final ClubCreationRequest request;
  final bool saving;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              request.clubName,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Chip(
              label: Text(request.status),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${request.category} · Requested by ${request.requesterName ?? 'Student'}',
        ),
        const SizedBox(height: 10),
        Text(request.description),
        if (request.contactEmail != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Contact: ${request.contactEmail}'),
          ),
        if (request.rejectionReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Reason: ${request.rejectionReason}'),
          ),
        if (request.status == 'PENDING')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: saving ? null : onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: saving ? null : onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _ClubFormData {
  const _ClubFormData(
    this.name,
    this.category,
    this.description,
    this.administratorIds,
    this.logoUrl,
    this.contactEmail,
  );
  final String name, category, description;
  final List<int> administratorIds;
  final String? logoUrl, contactEmail;
}

class _ClubEditorDialog extends StatefulWidget {
  const _ClubEditorDialog({required this.repository, this.club});
  final AdminClubRepository repository;
  final Club? club;
  @override
  State<_ClubEditorDialog> createState() => _ClubEditorDialogState();
}

class _ClubEditorDialogState extends State<_ClubEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.club?.name ?? '');
  late final _category = TextEditingController(
    text: widget.club?.category ?? '',
  );
  late final _description = TextEditingController(
    text: widget.club?.description ?? '',
  );
  late final _logo = TextEditingController(text: widget.club?.logoUrl ?? '');
  late final _email = TextEditingController(
    text: widget.club?.contactEmail ?? '',
  );
  final Set<int> _selected = {};
  String _search = '';
  bool _loadingStudents = true;
  List<EligibleClubAdministrator> _students = [];
  @override
  void initState() {
    super.initState();
    if (widget.club == null) _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final students = await widget.repository.students(search: _search);
      if (mounted) {
        setState(() {
          _students = students;
          _loadingStudents = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

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
    title: Text(widget.club == null ? 'Create club' : 'Edit club profile'),
    content: SizedBox(
      width: 500,
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
              if (widget.club == null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Initial club administrators',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Find an eligible student',
                  ),
                  onChanged: (value) {
                    _search = value.trim();
                    _loadStudents();
                  },
                ),
                if (_loadingStudents)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                else if (_students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No eligible students match this search.'),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final student in _students)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: _selected.contains(student.id),
                            title: Text(student.fullName),
                            subtitle: Text(student.email),
                            onChanged: (checked) => setState(() {
                              checked == true
                                  ? _selected.add(student.id)
                                  : _selected.remove(student.id);
                            }),
                          ),
                      ],
                    ),
                  ),
                if (_selected.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choose at least one administrator.'),
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
          if (widget.club == null && _selected.isEmpty) return;
          Navigator.pop(
            context,
            _ClubFormData(
              _name.text.trim(),
              _category.text.trim(),
              _description.text.trim(),
              _selected.toList(),
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

class _AssignAdministratorDialog extends StatefulWidget {
  const _AssignAdministratorDialog({
    required this.repository,
    required this.entry,
  });
  final AdminClubRepository repository;
  final ClubAdministrationEntry entry;
  @override
  State<_AssignAdministratorDialog> createState() =>
      _AssignAdministratorDialogState();
}

class _AssignAdministratorDialogState
    extends State<_AssignAdministratorDialog> {
  String _search = '';
  int? _selected;
  bool _loading = true;
  List<EligibleClubAdministrator> _students = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final students = await widget.repository.students(search: _search);
      final current = widget.entry.administrators
          .where((value) => value.current)
          .map((value) => value.userId)
          .toSet();
      if (mounted) {
        setState(() {
          _students = students
              .where((value) => !current.contains(value.id))
              .toList();
          _loading = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Add administrator · ${widget.entry.club.name}'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search students',
            ),
            onChanged: (value) {
              _search = value.trim();
              _load();
            },
          ),
          const SizedBox(height: 12),
          if (_loading)
            const CircularProgressIndicator()
          else if (_students.isEmpty)
            const Text('No eligible students found.')
          else
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Student'),
              items: [
                for (final student in _students)
                  DropdownMenuItem(
                    value: student.id,
                    child: Text(
                      '${student.fullName} · ${student.email}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _selected = value),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _selected == null
            ? null
            : () => Navigator.pop(context, _selected),
        child: const Text('Assign'),
      ),
    ],
  );
}

class _EmptyClubAdmin extends StatelessWidget {
  const _EmptyClubAdmin({required this.message, this.action});
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(
          Icons.groups_outlined,
          size: 34,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );
}
