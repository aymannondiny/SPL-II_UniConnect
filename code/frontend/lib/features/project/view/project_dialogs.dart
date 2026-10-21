import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/project/controller/project_finder_controller.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/model/project_models.dart';

String _projectErrorMessage(Object error, String fallback) =>
    error is AuthFailure ? error.message : fallback;

class ProjectFormDialog extends StatefulWidget {
  const ProjectFormDialog({this.project, super.key});
  final ProjectListing? project;

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _capacity;
  late final TextEditingController _duration;
  late final TextEditingController _course;
  late DateTime _deadline;
  late final List<_SkillEntry> _skills;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _title = TextEditingController(text: project?.title ?? '');
    _description = TextEditingController(text: project?.description ?? '');
    _capacity = TextEditingController(text: '${project?.teamSizeLimit ?? 4}');
    _duration = TextEditingController(text: project?.duration ?? '');
    _course = TextEditingController(text: project?.courseName ?? '');
    final parsed = DateTime.tryParse(project?.applicationDeadline ?? '');
    final today = DateTime.now();
    final candidateDeadline = parsed ?? today.add(const Duration(days: 30));
    _deadline =
        DateTime(
          candidateDeadline.year,
          candidateDeadline.month,
          candidateDeadline.day,
        ).isBefore(DateTime(today.year, today.month, today.day))
        ? DateTime(today.year, today.month, today.day)
        : DateTime(
            candidateDeadline.year,
            candidateDeadline.month,
            candidateDeadline.day,
          );
    _skills = project == null || project.skills.isEmpty
        ? [_SkillEntry()]
        : project.skills
              .map(
                (skill) => _SkillEntry(
                  value: skill.name,
                  isRequired: skill.isRequired,
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _capacity.dispose();
    _duration.dispose();
    _course.dispose();
    for (final skill in _skills) {
      skill.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseDeadline() async {
    final now = DateTime.now();
    final latestYear = _deadline.year > now.year + 10
        ? _deadline.year + 1
        : now.year + 10;
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(latestYear),
      helpText: 'Last day to apply',
    );
    if (selected != null) setState(() => _deadline = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final selectedSkills = _skills
        .where((skill) => skill.controller.text.trim().isNotEmpty)
        .map(
          (skill) => (
            name: skill.controller.text.trim(),
            isRequired: skill.isRequired,
          ),
        )
        .toList();
    if (selectedSkills.isEmpty ||
        !selectedSkills.any((skill) => skill.isRequired)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one required skill.')),
      );
      return;
    }
    final normalized = selectedSkills
        .map((skill) => skill.name.toLowerCase())
        .toSet();
    if (normalized.length != selectedSkills.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each skill can be added only once.')),
      );
      return;
    }
    final capacity = int.tryParse(_capacity.text.trim());
    if (capacity == null || capacity < 2 || capacity > 100) return;
    Navigator.of(context).pop(
      ProjectRequestData(
        title: _title.text,
        description: _description.text,
        teamSizeLimit: capacity,
        duration: _duration.text,
        courseName: _course.text,
        applicationDeadline: _deadline,
        skills: selectedSkills,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 760),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project == null
                                ? 'Post a project'
                                : 'Edit project',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find people to build with. Your team can choose the final topic together.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _title,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Listing title',
                          hintText: 'e.g. Form a team for a software project',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a listing title.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          labelText: 'What are you looking for?',
                          hintText: 'Describe the skills, goal, and how you want to work together.',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Add a short description.'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 440;
                          final capacity = TextFormField(
                            controller: _capacity,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Team size',
                              helperText: 'Includes you (2–100)',
                            ),
                            validator: (value) {
                              final parsed = int.tryParse(value ?? '');
                              if (parsed == null ||
                                  parsed < 2 ||
                                  parsed > 100) {
                                return 'Use a number from 2 to 100.';
                              }
                              return null;
                            },
                          );
                          final deadline = OutlinedButton.icon(
                            onPressed: _chooseDeadline,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text('Deadline · ${_formatDate(_deadline)}'),
                          );
                          return stacked
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    capacity,
                                    const SizedBox(height: 14),
                                    deadline,
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: capacity),
                                    const SizedBox(width: 14),
                                    Expanded(child: deadline),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 440;
                          final course = TextFormField(
                            controller: _course,
                            maxLength: 200,
                            decoration: const InputDecoration(
                              labelText: 'Course (optional)',
                              counterText: '',
                            ),
                          );
                          final duration = TextFormField(
                            controller: _duration,
                            maxLength: 200,
                            decoration: const InputDecoration(
                              labelText: 'Duration (optional)',
                              hintText: 'e.g. One semester',
                              counterText: '',
                            ),
                          );
                          return stacked
                              ? Column(
                                  children: [
                                    course,
                                    const SizedBox(height: 14),
                                    duration,
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: course),
                                    const SizedBox(width: 14),
                                    Expanded(child: duration),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Skills',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _skills.add(_SkillEntry())),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add skill'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (var index = 0; index < _skills.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _skills[index].controller,
                                  maxLength: 60,
                                  decoration: const InputDecoration(
                                    labelText: 'Skill name',
                                    counterText: '',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Tooltip(
                                message: _skills[index].isRequired
                                    ? 'Required skill'
                                    : 'Optional skill',
                                child: FilterChip(
                                  label: Text(
                                    _skills[index].isRequired
                                        ? 'Required'
                                        : 'Optional',
                                  ),
                                  selected: _skills[index].isRequired,
                                  onSelected: (value) => setState(
                                    () => _skills[index].isRequired = value,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _skills.length == 1
                                    ? null
                                    : () => setState(() {
                                        _skills.removeAt(index).dispose();
                                      }),
                                icon: const Icon(Icons.remove_circle_outline),
                                tooltip: 'Remove skill',
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 10,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.icon(
                              onPressed: _submit,
                              icon: Icon(
                                widget.project == null
                                    ? Icons.add
                                    : Icons.save_outlined,
                                size: 18,
                              ),
                              label: Text(
                                widget.project == null
                                    ? 'Post listing'
                                    : 'Save changes',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillEntry {
  _SkillEntry({String value = '', this.isRequired = true})
    : controller = TextEditingController(text: value);
  final TextEditingController controller;
  bool isRequired;
  void dispose() => controller.dispose();
}

class ProjectApplyDialog extends StatefulWidget {
  const ProjectApplyDialog({required this.project, super.key});
  final ProjectListing project;

  @override
  State<ProjectApplyDialog> createState() => _ProjectApplyDialogState();
}

class _ProjectApplyDialogState extends State<ProjectApplyDialog> {
  final _message = TextEditingController();
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Apply to join'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _message,
            maxLength: 500,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message to the project owner (optional)',
              hintText: 'Share how you could contribute.',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.pop(context, _message.text.trim()),
        icon: const Icon(Icons.send_outlined, size: 18),
        label: const Text('Send application'),
      ),
    ],
  );
}

class ProjectCandidatesDialog extends StatefulWidget {
  const ProjectCandidatesDialog({
    required this.repository,
    this.initialSkill = '',
    super.key,
  });
  final ProjectRepository repository;
  final String initialSkill;

  @override
  State<ProjectCandidatesDialog> createState() =>
      _ProjectCandidatesDialogState();
}

class _ProjectCandidatesDialogState extends State<ProjectCandidatesDialog> {
  late final TextEditingController _name;
  late final TextEditingController _skill;
  List<ProjectDepartment> _departments = [];
  List<ProjectCandidate> _candidates = [];
  int? _departmentId;
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _skill = TextEditingController(text: widget.initialSkill);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _name.dispose();
    _skill.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final departments = await widget.repository.departments();
      if (!mounted) return;
      setState(() => _departments = departments);
    } on Object {
      // Department filtering is optional; still let people search candidates.
    }
    if (!mounted) return;
    await _search();
  }

  Future<void> _search({bool more = false}) async {
    if (more && _loadingMore) return;
    setState(() {
      _error = null;
      _loading = !more;
      _loadingMore = more;
    });
    final page = more ? _page + 1 : 0;
    try {
      final result = await widget.repository.candidates(
        name: _name.text,
        departmentId: _departmentId,
        skill: _skill.text,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        _candidates = more ? [..._candidates, ...result.items] : result.items;
        _total = result.totalElements;
        _page = page;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = _projectErrorMessage(
          error,
          'Could not search for teammates. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 820),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.person_search_outlined, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find teammates',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Search students who are open to project work.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final department = DropdownButtonFormField<int?>(
                    initialValue: _departmentId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All departments'),
                      ),
                      for (final item in _departments)
                        DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(
                            item.code.isEmpty
                                ? item.name
                                : '${item.code} · ${item.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _departmentId = value),
                  );
                  final fields = <Widget>[
                    TextField(
                      controller: _name,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    TextField(
                      controller: _skill,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Skill',
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                    ),
                    department,
                    FilledButton.icon(
                      onPressed: _loading ? null : () => _search(),
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ];
                  return constraints.maxWidth < 650
                      ? Column(
                          children: [
                            for (final field in fields)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: field,
                              ),
                          ],
                        )
                      : Row(
                          children: [
                            for (var index = 0; index < fields.length; index++)
                              Expanded(
                                flex: index == 2 ? 2 : 1,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: index == fields.length - 1 ? 0 : 10,
                                  ),
                                  child: fields[index],
                                ),
                              ),
                          ],
                        );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : _candidates.isEmpty
                  ? const _DialogEmpty(
                      icon: Icons.person_search_outlined,
                      title: 'No students found',
                      message: 'Try a different name, department, or skill.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount:
                          _candidates.length +
                          (_candidates.length < _total ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == _candidates.length) {
                          return Center(
                            child: OutlinedButton.icon(
                              onPressed: _loadingMore
                                  ? null
                                  : () => _search(more: true),
                              icon: _loadingMore
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.expand_more),
                              label: const Text('Load more'),
                            ),
                          );
                        }
                        return _CandidateTile(candidate: _candidates[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class ProjectDetailsDialog extends StatefulWidget {
  const ProjectDetailsDialog({
    required this.project,
    required this.repository,
    super.key,
  });
  final ProjectListing project;
  final ProjectRepository repository;

  @override
  State<ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<ProjectDetailsDialog> {
  late Future<List<ProjectMember>> _members;
  @override
  void initState() {
    super.initState();
    _members = widget.repository.members(widget.project.id);
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(status: project.availability),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(project.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.groups_outlined,
                        label:
                            '${project.membershipCount} of ${project.teamSizeLimit} teammates',
                      ),
                      _InfoChip(
                        icon: Icons.event_outlined,
                        label:
                            'Apply by ${_formatDateString(project.applicationDeadline)}',
                      ),
                      if (project.courseName != null)
                        _InfoChip(
                          icon: Icons.menu_book_outlined,
                          label: project.courseName!,
                        ),
                      if (project.duration != null)
                        _InfoChip(
                          icon: Icons.schedule_outlined,
                          label: project.duration!,
                        ),
                    ],
                  ),
                  if (project.skills.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Skills',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final skill in project.skills)
                          _SkillChip(skill: skill),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Project team',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<ProjectMember>>(
                    future: _members,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return const Text('Unable to load team members.');
                      }
                      return Column(
                        children: [
                          for (final member in snapshot.data ?? [])
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                child: Text(_initials(member.displayName)),
                              ),
                              title: Text(member.displayName),
                              subtitle: Text(
                                member.role == 'CREATOR'
                                    ? 'Project creator'
                                    : 'Teammate',
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate});
  final ProjectCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(
              name: candidate.fullName,
              imageUrl: candidate.profilePhotoUrl,
              size: 46,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          candidate.fullName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (candidate.connectionStatus == 'ACCEPTED')
                        const Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('Connected'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      candidate.departmentName,
                      candidate.programmeName,
                      if (candidate.yearOfStudy != null)
                        'Year ${candidate.yearOfStudy}',
                    ].whereType<String>().join(' · '),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (candidate.skills.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final skill in candidate.skills.take(8))
                          Chip(
                            label: Text(skill),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Tooltip(
              message: 'Open to project work',
              child: Icon(Icons.handshake_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.item});
  final ProjectRecommendation item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(
              name: item.displayName,
              imageUrl: item.profilePhotoUrl,
              size: 46,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (item.departmentName != null)
                    Text(
                      item.departmentName!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final skill in item.matchedRequiredSkills)
                        Chip(
                          label: Text(skill),
                          avatar: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      for (final skill in item.matchedOptionalSkills)
                        Chip(
                          label: Text(skill),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill});
  final ProjectSkill skill;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: skill.isRequired ? const Icon(Icons.check, size: 15) : null,
    label: Text('${skill.name}${skill.isRequired ? ' · required' : ''}'),
    visualDensity: VisualDensity.compact,
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 16),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (status) {
      'AVAILABLE' || 'OPEN' || 'ACCEPTED' => colors.primary,
      'PENDING' => colors.secondary,
      'FULL' => colors.tertiary,
      'CLOSED' ||
      'EXPIRED' ||
      'REJECTED' ||
      'CANCELLED_PROJECT_DELETED' => colors.error,
      _ => colors.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _humanize(status),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.imageUrl,
    required this.size,
  });
  final String name;
  final String? imageUrl;
  final double size;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
    onBackgroundImageError: imageUrl == null ? null : (_, _) {},
    child: imageUrl == null
        ? Text(
            _initials(name),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          )
        : null,
  );
}

class _DialogEmpty extends StatelessWidget {
  const _DialogEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
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
        ],
      ),
    ),
  );
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  final value = parts.map((part) => part[0]).join();
  return value.isEmpty ? 'U' : value.toUpperCase();
}

String _humanize(String value) => value
    .toLowerCase()
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _shortDate(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return '';
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _formatDateString(String value) {
  final date = DateTime.tryParse(value);
  return date == null ? value : _formatDate(date);
}
