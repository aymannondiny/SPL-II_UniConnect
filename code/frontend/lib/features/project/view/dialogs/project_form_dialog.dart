part of '../project_dialogs.dart';

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
    final today = ProjectFormValidation.today();
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
    final now = ProjectFormValidation.today();
    final latestYear = _deadline.year > now.year + 10
        ? _deadline.year + 1
        : now.year + 10;
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(latestYear),
      helpText: 'Last day to apply (Asia/Dhaka)',
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
    final skillError = ProjectFormValidation.skills(selectedSkills);
    if (skillError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(skillError)));
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
                            validator: (value) =>
                                ProjectFormValidation.capacity(
                                  value,
                                  membershipCount:
                                      widget.project?.membershipCount ?? 1,
                                ),
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
                      const SizedBox(height: 6),
                      Text(
                        'Deadlines use Asia/Dhaka time.',
                        style: theme.textTheme.bodySmall,
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
                            onPressed:
                                _skills.length >=
                                    ProjectFormValidation.maxSkills
                                ? null
                                : () => setState(
                                    () => _skills.add(_SkillEntry()),
                                  ),
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
