import 'package:flutter/material.dart';
import 'package:uniconnect/features/career/model/career_models.dart';

class CareerPostFormDialog extends StatefulWidget {
  const CareerPostFormDialog({this.initial, super.key});

  final CareerPost? initial;

  @override
  State<CareerPostFormDialog> createState() => _CareerPostFormDialogState();
}

class _CareerPostFormDialogState extends State<CareerPostFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late final List<_SkillEditor> _skills;
  late CareerEmploymentType _employmentType;
  late CareerWorkMode _workMode;
  late DateTime _deadline;
  String? _skillError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _fields = {
      'title': TextEditingController(text: initial?.title ?? ''),
      'company': TextEditingController(text: initial?.companyName ?? ''),
      'description': TextEditingController(text: initial?.description ?? ''),
      'qualifications': TextEditingController(
        text: initial?.qualifications ?? '',
      ),
      'location': TextEditingController(text: initial?.location ?? ''),
      'salary': TextEditingController(text: initial?.salaryRange ?? ''),
      'url': TextEditingController(text: initial?.applicationUrl ?? ''),
      'email': TextEditingController(text: initial?.applicationEmail ?? ''),
    };
    _skills = [
      if (initial != null)
        for (final skill in initial.skills)
          _SkillEditor(skill.name, skill.required),
      if (initial == null || initial.skills.isEmpty) _SkillEditor('', true),
    ];
    _employmentType =
        initial?.employmentType ?? CareerEmploymentType.internship;
    _workMode = initial?.workMode ?? CareerWorkMode.hybrid;
    final today = DateUtils.dateOnly(DateTime.now());
    final candidate =
        initial?.applicationDeadline ?? today.add(const Duration(days: 14));
    _deadline = candidate.isBefore(today) ? today : candidate;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final skill in _skills) {
      skill.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, {required int max, required String label}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$label is required.';
    if (trimmed.length > max) return '$label must be $max characters or fewer.';
    return null;
  }

  String? _optional(String? value, {required int max, required String label}) {
    if ((value?.trim().length ?? 0) > max) {
      return '$label must be $max characters or fewer.';
    }
    return null;
  }

  Future<void> _pickDeadline() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(today) ? today : _deadline,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
      helpText: 'Application deadline',
    );
    if (picked != null) setState(() => _deadline = DateUtils.dateOnly(picked));
  }

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')} '
      '${_month(value.month)} ${value.year}';

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  void _submit() {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final url = _fields['url']!.text.trim();
    final email = _fields['email']!.text.trim();
    if (url.isEmpty && email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an application URL or email.')),
      );
      return;
    }
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme.toLowerCase() != 'https' ||
          uri.host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application links must use HTTPS.')),
        );
        return;
      }
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid application email.')),
      );
      return;
    }
    final names = <String>{};
    final skills = <CareerSkillInput>[];
    for (final editor in _skills) {
      final name = editor.controller.text.trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      if (name.isEmpty) continue;
      if (name.length > 60) {
        setState(
          () => _skillError = 'Skill names must be 60 characters or fewer.',
        );
        return;
      }
      if (!names.add(name.toLowerCase())) {
        setState(() => _skillError = 'Each skill can only be listed once.');
        return;
      }
      skills.add(CareerSkillInput(name: name, required: editor.required));
    }
    setState(() {
      _skillError = null;
      _submitting = true;
    });
    Navigator.of(context).pop(
      CareerPostInput(
        title: _fields['title']!.text.trim(),
        companyName: _fields['company']!.text.trim(),
        description: _fields['description']!.text.trim(),
        qualifications: _fields['qualifications']!.text.trim(),
        location: _fields['location']!.text.trim(),
        employmentType: _employmentType,
        workMode: _workMode,
        salaryRange: _fields['salary']!.text.trim(),
        applicationUrl: url,
        applicationEmail: email,
        applicationDeadline: _deadline,
        skills: skills,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.initial != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing ? 'Edit opportunity' : 'Share an opportunity',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add clear details so students know what to expect.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _field('title', 'Job title', max: 200, required: true),
                    const SizedBox(height: 14),
                    _field(
                      'company',
                      'Company or organization',
                      max: 200,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 500;
                        final type =
                            DropdownButtonFormField<CareerEmploymentType>(
                              initialValue: _employmentType,
                              decoration: const InputDecoration(
                                labelText: 'Employment type',
                              ),
                              items: [
                                for (final value in CareerEmploymentType.values)
                                  DropdownMenuItem(
                                    value: value,
                                    child: Text(value.label),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _employmentType = value!),
                            );
                        final mode = DropdownButtonFormField<CareerWorkMode>(
                          initialValue: _workMode,
                          decoration: const InputDecoration(
                            labelText: 'Work mode',
                          ),
                          items: [
                            for (final value in CareerWorkMode.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value.label),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _workMode = value!),
                        );
                        return wide
                            ? Row(
                                children: [
                                  Expanded(child: type),
                                  const SizedBox(width: 12),
                                  Expanded(child: mode),
                                ],
                              )
                            : Column(
                                children: [
                                  type,
                                  const SizedBox(height: 14),
                                  mode,
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 500;
                        final location = _field(
                          'location',
                          'Location',
                          max: 200,
                        );
                        final salary = _field(
                          'salary',
                          'Salary range (optional)',
                          max: 200,
                        );
                        return wide
                            ? Row(
                                children: [
                                  Expanded(child: location),
                                  const SizedBox(width: 12),
                                  Expanded(child: salary),
                                ],
                              )
                            : Column(
                                children: [
                                  location,
                                  const SizedBox(height: 14),
                                  salary,
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 14),
                    _field(
                      'description',
                      'Opportunity description',
                      max: 5000,
                      required: true,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      'qualifications',
                      'Qualifications',
                      max: 5000,
                      required: true,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Skills',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mark each skill as required or preferred. You can leave this list empty.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _skills.length; i++) _skillRow(i),
                    if (_skillError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _skillError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _skills.add(_SkillEditor('', true))),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add a skill'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDeadline,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        'Application deadline · ${_dateLabel(_deadline)}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field('url', 'Application URL (HTTPS)', max: 2048),
                    const SizedBox(height: 14),
                    _field('email', 'Application email', max: 320),
                    const SizedBox(height: 4),
                    Text(
                      'Provide at least one application channel. If you add both, students can choose.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.publish_outlined),
                    label: Text(editing ? 'Save changes' : 'Publish'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    required int max,
    bool required = false,
    int maxLines = 1,
  }) => TextFormField(
    controller: _fields[key],
    maxLength: max,
    maxLines: maxLines,
    minLines: maxLines == 1 ? 1 : maxLines,
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: maxLines > 1,
    ),
    validator: (value) => required
        ? _required(value, max: max, label: label)
        : _optional(value, max: max, label: label),
  );

  Widget _skillRow(int index) {
    final editor = _skills[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final requiredToggle = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: editor.required,
                onChanged: (value) =>
                    setState(() => editor.required = value ?? false),
              ),
              const Text('Required', style: TextStyle(fontSize: 13)),
            ],
          );
          final skillField = TextField(
            controller: editor.controller,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: 'Skill ${index + 1}',
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
            onChanged: (_) => setState(() => _skillError = null),
          );
          return Row(
            children: [
              Expanded(child: skillField),
              requiredToggle,
              IconButton(
                tooltip: 'Remove skill',
                onPressed: _skills.length == 1
                    ? () => setState(() => editor.controller.clear())
                    : () => setState(() {
                        _skills.removeAt(index).dispose();
                        _skillError = null;
                      }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SkillEditor {
  _SkillEditor(String name, this.required)
    : controller = TextEditingController(text: name);

  final TextEditingController controller;
  bool required;

  void dispose() => controller.dispose();
}
