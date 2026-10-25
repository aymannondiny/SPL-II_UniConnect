part of '../project_dialogs.dart';

class ProjectManageDialog extends StatefulWidget {
  const ProjectManageDialog({
    required this.project,
    required this.controller,
    required this.onEdit,
    super.key,
  });
  final ProjectListing project;
  final ProjectFinderController controller;
  final VoidCallback onEdit;

  @override
  State<ProjectManageDialog> createState() => _ProjectManageDialogState();
}

class _ProjectManageDialogState extends State<ProjectManageDialog> {
  bool _loading = true;
  String? _error;
  List<ProjectApplication> _applications = [];
  List<ProjectRecommendation> _recommendations = [];
  List<ProjectMember> _members = [];
  List<ProjectAuditEntry> _audit = [];

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
      final values = await Future.wait([
        widget.controller.repository.applications(widget.project.id),
        widget.controller.repository.recommendations(widget.project.id),
        widget.controller.repository.members(widget.project.id),
        widget.controller.repository.audit(widget.project.id),
      ]);
      if (!mounted) return;
      setState(() {
        _applications = (values[0] as ProjectPage<ProjectApplication>).items;
        _recommendations = values[1] as List<ProjectRecommendation>;
        _members = values[2] as List<ProjectMember>;
        _audit = (values[3] as ProjectPage<ProjectAuditEntry>).items;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = _projectErrorMessage(
          error,
          'Could not load this project’s team details. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(ProjectApplication application, String decision) async {
    final success = await widget.controller.reviewApplication(
      application.id,
      decision,
    );
    if (success && mounted) await _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this listing?'),
        content: const Text(
          'This permanently closes the listing and cancels all pending applications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep listing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete listing'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await widget.controller.deleteProject(widget.project.id);
    if (deleted && mounted) Navigator.pop(context);
  }

  Future<void> _closeOrReopen() async {
    final wasOpen = widget.project.status == 'OPEN';
    final success = wasOpen
        ? await widget.controller.closeProject(widget.project.id)
        : await widget.controller.reopenProject(widget.project.id);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940, maxHeight: 840),
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.project.membershipCount}/${widget.project.teamSizeLimit} teammates · ${widget.project.status.toLowerCase()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit listing',
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'More listing actions',
                      onSelected: (action) {
                        if (action == 'close' || action == 'reopen') {
                          _closeOrReopen();
                        }
                        if (action == 'delete') {
                          _delete();
                        }
                      },
                      itemBuilder: (context) => [
                        if (widget.project.status == 'OPEN')
                          const PopupMenuItem(
                            value: 'close',
                            child: Text('Close listing'),
                          ),
                        if (widget.project.status == 'CLOSED')
                          const PopupMenuItem(
                            value: 'reopen',
                            child: Text('Reopen listing'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete listing'),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Applications'),
                  Tab(text: 'Suggested teammates'),
                  Tab(text: 'Team members'),
                  Tab(text: 'Activity'),
                ],
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _DialogError(message: _error!, onRetry: _load)
                    : TabBarView(
                        children: [
                          _applicationsTab(),
                          _recommendationsTab(),
                          _membersTab(),
                          _auditTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _applicationsTab() {
    if (_applications.isEmpty) {
      return const _DialogEmpty(
        icon: Icons.inbox_outlined,
        title: 'No applications yet',
        message: 'New applications for this listing will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _applications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final application = _applications[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        application.applicantDisplayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _StatusBadge(status: application.status),
                  ],
                ),
                if (application.message?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(application.message!),
                ],
                if (application.status == 'PENDING') ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: widget.controller.mutating
                            ? null
                            : () => _review(application, 'accept'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accept'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.controller.mutating
                            ? null
                            : () => _review(application, 'reject'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Decline'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _recommendationsTab() {
    if (_recommendations.isEmpty) {
      return const _DialogEmpty(
        icon: Icons.auto_awesome_outlined,
        title: 'No matches yet',
        message: 'Recommendations show students who opted in and match at least one required skill.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _recommendations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _RecommendationTile(item: _recommendations[index]),
    );
  }

  Widget _membersTab() {
    if (_members.isEmpty) {
      return const _DialogEmpty(
        icon: Icons.groups_outlined,
        title: 'No teammates yet',
        message:
            'The project creator will be listed once the listing is created.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _members.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = _members[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          leading: CircleAvatar(child: Text(_initials(member.displayName))),
          title: Text(member.displayName),
          subtitle: Text(
            member.role == 'CREATOR' ? 'Project creator' : 'Teammate',
          ),
          trailing: Text(
            _shortDate(member.joinedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }

  Widget _auditTab() {
    if (_audit.isEmpty) {
      return const _DialogEmpty(
        icon: Icons.history,
        title: 'No activity yet',
        message: 'Project actions will appear in this history.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _audit.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _audit[index];
        return ListTile(
          leading: const Icon(Icons.circle, size: 10),
          title: Text(_humanize(item.eventType)),
          subtitle: Text(
            item.applicationId == null
                ? 'Project activity'
                : 'Application #${item.applicationId}',
          ),
          trailing: Text(
            _shortDate(item.occurredAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}
