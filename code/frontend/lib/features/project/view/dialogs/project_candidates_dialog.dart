part of '../project_dialogs.dart';

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
  late final TextEditingController _requiredSkills;
  late final TextEditingController _optionalSkills;
  List<ProjectDepartment> _departments = [];
  List<ProjectCandidate> _candidates = [];
  int? _departmentId;
  bool? _projectAvailable;
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _requiredSkills = TextEditingController(text: widget.initialSkill);
    _optionalSkills = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _requiredSkills.dispose();
    _optionalSkills.dispose();
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
    final requiredSkills = _skillList(_requiredSkills.text);
    if (requiredSkills.isEmpty) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Enter at least one required skill to search.';
        _candidates = [];
        _total = 0;
      });
      return;
    }
    setState(() {
      _error = null;
      _loading = !more;
      _loadingMore = more;
    });
    final page = more ? _page + 1 : 0;
    try {
      final result = await widget.repository.candidates(
        requiredSkills: requiredSkills,
        optionalSkills: _skillList(_optionalSkills.text),
        departmentId: _departmentId,
        projectAvailable: _projectAvailable,
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

  List<String> _skillList(String value) => value
      .split(',')
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toList();

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
                          'Match every required skill; optional skills only add visible context.',
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
                  final availability = DropdownButtonFormField<bool?>(
                    initialValue: _projectAvailable,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Availability',
                    ),
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('Any availability'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Available'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Unavailable'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _projectAvailable = value),
                  );
                  final fields = <Widget>[
                    TextField(
                      controller: _requiredSkills,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Required skills',
                        hintText: 'Java, Spring',
                        prefixIcon: Icon(Icons.checklist_outlined),
                      ),
                    ),
                    TextField(
                      controller: _optionalSkills,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Optional skills',
                        hintText: 'SQL, Docker',
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                    ),
                    department,
                    availability,
                    FilledButton.icon(
                      onPressed: _loading ? null : () => _search(),
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ];
                  return constraints.maxWidth < 850
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
                      message: 'Try different required skills or filters.',
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
