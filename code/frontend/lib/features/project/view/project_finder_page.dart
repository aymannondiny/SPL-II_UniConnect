import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/project/controller/project_finder_controller.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/model/project_models.dart';
import 'package:uniconnect/features/project/view/project_dialogs.dart';

/// Project recruitment workspace, following the wireframe's listing cards and
/// Open projects / My posts / Applied tabs.
class ProjectFinderPage extends StatefulWidget {
  const ProjectFinderPage({
    required this.repository,
    required this.session,
    this.active = true,
    super.key,
  });

  final ProjectRepository repository;
  final SessionController session;
  final bool active;

  @override
  State<ProjectFinderPage> createState() => _ProjectFinderPageState();
}

class _ProjectFinderPageState extends State<ProjectFinderPage> {
  late final ProjectFinderController _controller;
  final _skillFilter = TextEditingController();
  List<ProjectDepartment> _departments = [];
  String? _shownError;

  @override
  void initState() {
    super.initState();
    _controller = ProjectFinderController(widget.repository);
    _controller.addListener(_onControllerChange);
    unawaited(_controller.loadOpen());
    unawaited(_loadDepartments());
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await widget.repository.departments();
      if (mounted) setState(() => _departments = departments);
    } on Object {
      // Search remains usable without the optional department filter.
    }
  }

  void _onControllerChange() {
    if (!mounted) return;
    final error = _controller.error;
    if (error == null) {
      _shownError = null;
      return;
    }
    if (_shownError == error) return;
    _shownError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: _controller.clearError,
            ),
          ),
        );
    });
  }

  @override
  void didUpdateWidget(covariant ProjectFinderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.refreshActiveTab();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _skillFilter.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final request = await showDialog<ProjectRequestData>(
      context: context,
      builder: (_) => const ProjectFormDialog(),
    );
    if (request == null || !mounted) return;
    final created = await _controller.createProject(request);
    if (created != null && mounted) {
      _controller.selectTab(ProjectFinderTab.mine);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your project listing is live.')),
      );
    }
  }

  Future<void> _editProject(ProjectListing project) async {
    final request = await showDialog<ProjectRequestData>(
      context: context,
      builder: (_) => ProjectFormDialog(project: project),
    );
    if (request == null || !mounted) return;
    final updated = await _controller.updateProject(project.id, request);
    if (updated != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project listing updated.')));
    }
  }

  Future<void> _apply(ProjectListing project) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => ProjectApplyDialog(project: project),
    );
    if (message == null || !mounted) return;
    final sent = await _controller.apply(project.id, message);
    if (sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application sent to the project owner.')),
      );
    }
  }

  void _showCandidateSearch({String initialSkill = ''}) {
    showDialog<void>(
      context: context,
      builder: (_) => ProjectCandidatesDialog(
        repository: widget.repository,
        initialSkill: initialSkill,
      ),
    );
  }

  void _showDetails(ProjectListing project) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          ProjectDetailsDialog(project: project, repository: widget.repository),
    );
  }

  void _showManage(ProjectListing project) {
    showDialog<void>(
      context: context,
      builder: (_) => ProjectManageDialog(
        project: project,
        controller: _controller,
        onEdit: (latest) {
          Navigator.of(context).pop();
          _editProject(latest);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = widget.session.account?.userId;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageHeader(theme),
          const SizedBox(height: 22),
          _tabBar(theme),
          const SizedBox(height: 18),
          if (_controller.error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _controller.error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    TextButton.icon(
                      onPressed: _controller.refreshActiveTab,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          switch (_controller.activeTab) {
            ProjectFinderTab.open => _openProjects(currentUserId),
            ProjectFinderTab.mine => _myProjects(),
            ProjectFinderTab.applied => _appliedProjects(),
          },
        ],
      ),
    );
  }

  Widget _pageHeader(ThemeData theme) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      final actions = Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _showCandidateSearch(),
            icon: const Icon(Icons.person_search_outlined, size: 18),
            label: const Text('Find teammates'),
          ),
          FilledButton.icon(
            onPressed: _controller.mutating ? null : _createProject,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Post a project'),
          ),
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Project finder',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton.outlined(
                  onPressed: _controller.refreshActiveTab,
                  icon: const Icon(Icons.refresh, size: 19),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Find teammates or join a project that needs your skills.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            actions,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project finder',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Find teammates or join a project that needs your skills.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  onPressed: _controller.refreshActiveTab,
                  icon: const Icon(Icons.refresh, size: 19),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 10),
                actions,
              ],
            ),
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
            'Open projects',
            Icons.layers_outlined,
            ProjectFinderTab.open,
            theme,
          ),
          _tabItem(
            'My posts',
            Icons.folder_open_outlined,
            ProjectFinderTab.mine,
            theme,
          ),
          _tabItem(
            'Applied',
            Icons.assignment_outlined,
            ProjectFinderTab.applied,
            theme,
          ),
        ],
      ),
    ),
  );

  Widget _tabItem(
    String label,
    IconData icon,
    ProjectFinderTab tab,
    ThemeData theme,
  ) {
    final selected = _controller.activeTab == tab;
    final count = switch (tab) {
      ProjectFinderTab.open => _controller.openTotal,
      ProjectFinderTab.mine => _controller.myTotal,
      ProjectFinderTab.applied => _controller.appliedTotal,
    };
    return InkWell(
      onTap: () => _controller.selectTab(tab),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
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
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: .12)
                    : theme.colorScheme.surfaceContainerHighest,
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

  Widget _openProjects(int? currentUserId) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _filterBar(),
      const SizedBox(height: 16),
      _resultCount(
        _controller.openTotal,
        'open project${_controller.openTotal == 1 ? '' : 's'}',
      ),
      const SizedBox(height: 12),
      if (_controller.openLoading && _controller.openProjects.isEmpty)
        const _LoadingPanel()
      else if (_controller.openProjects.isEmpty)
        _EmptyPanel(
          icon: Icons.layers_outlined,
          title: 'No projects found',
          message: 'Try changing the filters, or post a project to start your own team.',
          action: FilledButton.icon(
            onPressed: _createProject,
            icon: const Icon(Icons.add),
            label: const Text('Post a project'),
          ),
        )
      else ...[
        _projectGrid(
          _controller.openProjects,
          ownerId: currentUserId,
          onDetails: _showDetails,
          onManage: _showManage,
          onApply: _apply,
        ),
        if (_controller.canLoadMoreOpen) ...[
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: _controller.openLoadingMore
                  ? null
                  : () => _controller.loadOpen(more: true),
              icon: _controller.openLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: const Text('Load more projects'),
            ),
          ),
        ],
      ],
    ],
  );

  Widget _myProjects() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _resultCount(
        _controller.myTotal,
        'listing${_controller.myTotal == 1 ? '' : 's'} you created',
      ),
      const SizedBox(height: 12),
      if (_controller.myLoading && _controller.myProjects.isEmpty)
        const _LoadingPanel()
      else if (_controller.myProjects.isEmpty)
        _EmptyPanel(
          icon: Icons.post_add_outlined,
          title: 'You haven’t posted a project yet',
          message: 'Create a listing and find students who want to work on the same goal.',
          action: FilledButton.icon(
            onPressed: _createProject,
            icon: const Icon(Icons.add),
            label: const Text('Post a project'),
          ),
        )
      else ...[
        _projectGrid(
          _controller.myProjects,
          ownerId: widget.session.account?.userId,
          onDetails: _showDetails,
          onManage: _showManage,
          onApply: _apply,
          manageOnly: true,
        ),
        if (_controller.canLoadMoreMine) ...[
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: _controller.myLoadingMore
                  ? null
                  : () => _controller.loadMine(more: true),
              icon: _controller.myLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: const Text('Load more listings'),
            ),
          ),
        ],
      ],
    ],
  );

  Widget _appliedProjects() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _resultCount(
        _controller.appliedTotal,
        'application${_controller.appliedTotal == 1 ? '' : 's'}',
      ),
      const SizedBox(height: 12),
      if (_controller.appliedLoading && _controller.applications.isEmpty)
        const _LoadingPanel()
      else if (_controller.applications.isEmpty)
        _EmptyPanel(
          icon: Icons.assignment_outlined,
          title: 'No applications yet',
          message: 'Projects you apply to will appear here so you can follow their status.',
          action: OutlinedButton.icon(
            onPressed: () => _controller.selectTab(ProjectFinderTab.open),
            icon: const Icon(Icons.search),
            label: const Text('Browse projects'),
          ),
        )
      else ...[
        for (final entry in _controller.applications)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AppliedCard(
              item: entry,
              onDetails: entry.project == null
                  ? null
                  : () => _showDetails(entry.project!),
            ),
          ),
        if (_controller.canLoadMoreApplied) ...[
          const SizedBox(height: 8),
          Center(
            child: OutlinedButton.icon(
              onPressed: _controller.appliedLoadingMore
                  ? null
                  : () => _controller.loadApplied(more: true),
              icon: _controller.appliedLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: const Text('Load more applications'),
            ),
          ),
        ],
      ],
    ],
  );

  Widget _filterBar() => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 780;
          final filters = <Widget>[
            TextField(
              controller: _skillFilter,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applyFilters(),
              decoration: const InputDecoration(
                labelText: 'Skill',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            DropdownButtonFormField<int?>(
              key: ValueKey('department-${_controller.filters.departmentId}'),
              initialValue: _controller.filters.departmentId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Department',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All departments'),
                ),
                for (final department in _departments)
                  DropdownMenuItem<int?>(
                    value: department.id,
                    child: Text(
                      department.code.isEmpty
                          ? department.name
                          : '${department.code} · ${department.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => _controller.updateFilters(
                _controller.filters.copyWith(
                  departmentId: value,
                  clearDepartment: value == null,
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('availability-${_controller.filters.availability}'),
              initialValue: _controller.filters.availability,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Availability',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('Available and full')),
                DropdownMenuItem(value: 'AVAILABLE', child: Text('Has room')),
                DropdownMenuItem(value: 'FULL', child: Text('Full teams')),
              ],
              onChanged: (value) => _controller.updateFilters(
                _controller.filters.copyWith(availability: value ?? ''),
              ),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('sort-${_controller.filters.sort}'),
              initialValue: _controller.filters.sort,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sort',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'CREATED_DESC', child: Text('Newest')),
                DropdownMenuItem(
                  value: 'DEADLINE_ASC',
                  child: Text('Deadline soonest'),
                ),
              ],
              onChanged: (value) => _controller.updateFilters(
                _controller.filters.copyWith(sort: value ?? 'CREATED_DESC'),
              ),
            ),
            FilledButton.icon(
              onPressed: _controller.openLoading ? null : _applyFilters,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Filter'),
            ),
            IconButton(
              onPressed: () {
                _skillFilter.clear();
                _controller.clearFilters();
              },
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Clear filters',
            ),
          ];
          if (narrow) {
            return Column(
              children: [
                for (final filter in filters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(width: double.infinity, child: filter),
                  ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 2, child: filters[0]),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: filters[1]),
              const SizedBox(width: 10),
              Expanded(child: filters[2]),
              const SizedBox(width: 10),
              Expanded(child: filters[3]),
              const SizedBox(width: 8),
              filters[4],
              filters[5],
            ],
          );
        },
      ),
    ),
  );

  void _applyFilters() {
    _controller.updateFilters(
      _controller.filters.copyWith(skill: _skillFilter.text),
    );
  }

  Widget _resultCount(int count, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(
      '$count $label',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );

  Widget _projectGrid(
    List<ProjectListing> projects, {
    required int? ownerId,
    required ValueChanged<ProjectListing> onDetails,
    required ValueChanged<ProjectListing> onManage,
    required ValueChanged<ProjectListing> onApply,
    bool manageOnly = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 980
          ? 3
          : width >= 640
          ? 2
          : 1;
      final gap = 14.0;
      final cardWidth = columns == 1
          ? width
          : (width - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final project in projects)
            SizedBox(
              width: cardWidth,
              child: _ProjectCard(
                project: project,
                owned: ownerId != null && ownerId == project.creatorUserId,
                manageOnly: manageOnly,
                onDetails: () => onDetails(project),
                onManage: () => onManage(project),
                onApply: () => onApply(project),
              ),
            ),
        ],
      );
    },
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.owned,
    required this.manageOnly,
    required this.onDetails,
    required this.onManage,
    required this.onApply,
  });

  final ProjectListing project;
  final bool owned;
  final bool manageOnly;
  final VoidCallback onDetails;
  final VoidCallback onManage;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canApply = !owned && project.canApply && !manageOnly;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 290),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ProjectStatus(status: project.availability),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  project.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                if (project.skills.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final skill in project.skills.take(4))
                        Chip(
                          label: Text(skill.name),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: skill.isRequired
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                        ),
                      if (project.skills.length > 4)
                        Chip(
                          label: Text('+${project.skills.length - 4}'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${project.membershipCount} of ${project.teamSizeLimit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value:
                              (project.membershipCount / project.teamSizeLimit)
                                  .clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: colors.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        _initials(project.creatorDisplayName),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          project.creatorDisplayName,
                          project.creatorDepartmentCode,
                        ].whereType<String>().join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      'By ${_formatDate(project.applicationDeadline)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: owned ? onManage : onDetails,
                        icon: Icon(
                          owned ? Icons.settings_outlined : Icons.open_in_new,
                          size: 17,
                        ),
                        label: Text(owned ? 'Manage' : 'Details'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: canApply ? onApply : null,
                        child: Text(
                          owned
                              ? 'Your post'
                              : switch (project.currentApplicationStatus) {
                                  'PENDING' => 'Applied',
                                  'ACCEPTED' => 'Accepted',
                                  'REJECTED' => 'Declined',
                                  'CANCELLED_PROJECT_DELETED' => 'Cancelled',
                                  _ => project.full ? 'Full' : 'Apply',
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppliedCard extends StatelessWidget {
  const _AppliedCard({required this.item, required this.onDetails});
  final AppliedProject item;
  final VoidCallback? onDetails;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final application = item.application;
    final project = item.project;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.layers_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project?.title ?? 'Deleted project listing',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project == null
                        ? 'This listing was deleted by its owner.'
                        : 'Applied ${_formatDate(application.appliedAt)} · ${project.creatorDisplayName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ProjectStatus(status: application.status),
            if (onDetails != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDetails,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'View project',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectStatus extends StatelessWidget {
  const _ProjectStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color color = switch (status) {
      'AVAILABLE' || 'OPEN' || 'ACCEPTED' => colors.primary,
      'PENDING' => colors.secondary,
      'FULL' => colors.tertiary,
      'CLOSED' ||
      'EXPIRED' ||
      'REJECTED' ||
      'CANCELLED_PROJECT_DELETED' => colors.error,
      _ => colors.onSurfaceVariant,
    };
    final label = status
        .toLowerCase()
        .split('_')
        .map(
          (part) => part.isEmpty
              ? ''
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 60),
    child: Center(child: CircularProgressIndicator()),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  final initials = parts.map((part) => part[0]).join();
  return initials.isEmpty ? 'U' : initials.toUpperCase();
}

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}
