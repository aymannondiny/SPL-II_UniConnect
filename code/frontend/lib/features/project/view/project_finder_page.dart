import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/project/controller/project_finder_controller.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/model/project_models.dart';
import 'package:uniconnect/features/project/view/project_dialogs.dart';

part 'widgets/project_card.dart';
part 'widgets/applied_project_card.dart';
part 'widgets/project_status.dart';
part 'widgets/project_state_panels.dart';
part 'widgets/project_card_format.dart';
part 'widgets/project_page_header.dart';
part 'widgets/project_filter_bar.dart';

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
