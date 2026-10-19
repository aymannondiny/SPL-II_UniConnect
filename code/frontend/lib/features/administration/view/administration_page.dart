import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/administration/data/admin_catalog_repository.dart';
import 'package:uniconnect/features/administration/model/admin_academic_catalog.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({required this.repository, super.key});
  final AdminCatalogRepository repository;

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  AdminAcademicCatalog? _catalog;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _selectedTab = 0;

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
      final catalog = await widget.repository.list();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
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
        _error = 'Unable to load the academic catalog. Please retry.';
        _loading = false;
      });
    }
  }

  Future<void> _edit({Object? item}) async {
    final catalog = _catalog;
    if (catalog == null || _saving) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          AcademicOptionDialog(tab: _selectedTab, catalog: catalog, item: item),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      switch (_selectedTab) {
        case 0:
          final department = item as AdminDepartment?;
          await widget.repository.saveDepartment(
            result['name'] as String,
            result['code'] as String,
            id: department?.id,
          );
          break;
        case 1:
          final programme = item as AdminProgramme?;
          await widget.repository.saveProgramme(
            result['name'] as String,
            result['code'] as String,
            result['departmentId'] as int,
            id: programme?.id,
          );
          break;
        case 2:
          final degree = item as AdminDegree?;
          await widget.repository.saveDegree(
            programmeId: result['programmeId'] as int,
            level: result['degreeLevel'] as String,
            durationYears: result['durationYears'] as int,
            minimumYear: result['minimumYear'] as int,
            maximumYear: result['maximumYear'] as int,
            active: result['active'] as bool,
            id: degree?.id,
          );
          break;
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? 'Catalog entry added.' : 'Changes saved.',
          ),
        ),
      );
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save this catalog entry.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _departmentName(int id) {
    for (final department in _catalog!.departments) {
      if (department.id == id) return department.name;
    }
    return 'Department';
  }

  String _programmeName(int id) {
    for (final programme in _catalog!.programmes) {
      if (programme.id == id) return programme.name;
    }
    return 'Programme';
  }

  Widget _catalogItems(AdminAcademicCatalog catalog) {
    final entries = switch (_selectedTab) {
      0 => catalog.departments,
      1 => catalog.programmes,
      _ => catalog.degrees,
    };
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _EmptyCatalog(onAdd: _saving ? null : () => _edit()),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          switch (_selectedTab) {
            0 => _departmentRow(entries[index] as AdminDepartment),
            1 => _programmeRow(entries[index] as AdminProgramme),
            _ => _degreeRow(entries[index] as AdminDegree),
          },
          if (index != entries.length - 1)
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: .2),
            ),
        ],
      ],
    );
  }

  Widget _departmentRow(AdminDepartment department) => _CatalogRow(
    icon: Icons.account_balance_outlined,
    title: department.name,
    subtitle: 'Code: ${department.code}',
    onEdit: _saving ? null : () => _edit(item: department),
  );

  Widget _programmeRow(AdminProgramme programme) => _CatalogRow(
    icon: Icons.menu_book_outlined,
    title: programme.name,
    subtitle: '${programme.code} · ${_departmentName(programme.departmentId)}',
    onEdit: _saving ? null : () => _edit(item: programme),
  );

  Widget _degreeRow(AdminDegree degree) => _CatalogRow(
    icon: Icons.school_outlined,
    title:
        '${_programmeName(degree.programmeId)} · ${degree.level.toLowerCase()}',
    subtitle:
        '${degree.durationYears} years · Study year ${degree.minimumYear}–${degree.maximumYear}',
    trailing: Chip(
      label: Text(degree.active ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
      backgroundColor: degree.active
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .12)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    onEdit: _saving ? null : () => _edit(item: degree),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = _catalog;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administration',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage departments, programmes and degree options.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (_loading && catalog == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null && catalog == null)
          SectionCard(
            title: 'Academic catalog',
            child: _EmptyCatalog(
              message: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          )
        else if (catalog != null) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 32) / 3
                  : constraints.maxWidth >= 460
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              final activeDegrees = catalog.degrees
                  .where((degree) => degree.active)
                  .length;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _StatCard(
                      label: 'Departments',
                      value: '${catalog.departments.length}',
                      icon: Icons.account_balance_outlined,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _StatCard(
                      label: 'Programmes',
                      value: '${catalog.programmes.length}',
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _StatCard(
                      label: 'Active degree options',
                      value: activeDegrees.toString(),
                      icon: Icons.school_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Academic catalog',
            subtitle: 'Changes are saved to the UniConnect academic catalog.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Departments')),
                    ButtonSegment(value: 1, label: Text('Programmes')),
                    ButtonSegment(value: 2, label: Text('Degrees')),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: _saving
                      ? null
                      : (value) => setState(() => _selectedTab = value.first),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : () => _edit(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(switch (_selectedTab) {
                      0 => 'Add department',
                      1 => 'Add programme',
                      _ => 'Add degree',
                    }),
                  ),
                ),
                if (_saving)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  const SizedBox(height: 2),
                _catalogItems(catalog),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: .11),
            foregroundColor: theme.colorScheme.primary,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
          IconButton(
            tooltip: 'Edit catalog entry',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({
    this.message = 'No entries yet. Add the first item to get started.',
    this.action,
    this.onAdd,
  });
  final String message;
  final Widget? action;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 38,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        ?action,
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add entry'),
          ),
      ],
    ),
  );
}

class AcademicOptionDialog extends StatefulWidget {
  const AcademicOptionDialog({
    required this.tab,
    required this.catalog,
    this.item,
    super.key,
  });
  final int tab;
  final AdminAcademicCatalog catalog;
  final Object? item;

  @override
  State<AcademicOptionDialog> createState() => _AcademicOptionDialogState();
}

class _AcademicOptionDialogState extends State<AcademicOptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: switch (widget.item) {
      AdminDepartment item => item.name,
      AdminProgramme item => item.name,
      _ => '',
    },
  );
  late final _code = TextEditingController(
    text: switch (widget.item) {
      AdminDepartment item => item.code,
      AdminProgramme item => item.code,
      _ => '',
    },
  );
  late final _duration = TextEditingController(
    text: widget.item is AdminDegree
        ? (widget.item as AdminDegree).durationYears.toString()
        : '4',
  );
  late final _minimumYear = TextEditingController(
    text: widget.item is AdminDegree
        ? (widget.item as AdminDegree).minimumYear.toString()
        : '1',
  );
  late final _maximumYear = TextEditingController(
    text: widget.item is AdminDegree
        ? (widget.item as AdminDegree).maximumYear.toString()
        : '4',
  );
  int? _parentId;
  String _level = 'BACHELOR';
  bool _active = true;

  @override
  void initState() {
    super.initState();
    switch (widget.item) {
      case AdminProgramme item:
        _parentId = item.departmentId;
      case AdminDegree item:
        _parentId = item.programmeId;
        _level = item.level;
        _active = item.active;
      default:
        if (widget.tab == 1 && widget.catalog.departments.isNotEmpty) {
          _parentId = widget.catalog.departments.first.id;
        }
        if (widget.tab == 2 && widget.catalog.programmes.isNotEmpty) {
          _parentId = widget.catalog.programmes.first.id;
        }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _duration.dispose();
    _minimumYear.dispose();
    _maximumYear.dispose();
    super.dispose();
  }

  String _title() {
    final name = switch (widget.tab) {
      0 => 'department',
      1 => 'programme',
      _ => 'degree',
    };
    return '${widget.item == null ? 'Add' : 'Edit'} $name';
  }

  Widget _numberField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final number = int.tryParse(value ?? '');
          if (number == null || number < 1 || number > 20) {
            return 'Enter a number from 1 to 20.';
          }
          return null;
        },
      );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.tab > 0 && _parentId == null) return;
    final result = <String, dynamic>{};
    if (widget.tab < 2) {
      result['name'] = _name.text.trim();
      result['code'] = _code.text.trim().toUpperCase();
    }
    if (widget.tab == 1) result['departmentId'] = _parentId;
    if (widget.tab == 2) {
      result.addAll({
        'programmeId': _parentId,
        'degreeLevel': _level,
        'durationYears': int.parse(_duration.text),
        'minimumYear': int.parse(_minimumYear.text),
        'maximumYear': int.parse(_maximumYear.text),
        'active': _active,
      });
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final hasParents = widget.tab == 1
        ? widget.catalog.departments.isNotEmpty
        : widget.catalog.programmes.isNotEmpty;
    return AlertDialog(
      title: Text(_title()),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.tab < 2) ...[
                  TextFormField(
                    controller: _name,
                    maxLength: 150,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a name.'
                        : null,
                  ),
                  TextFormField(
                    controller: _code,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      helperText: 'Letters, numbers, underscore or hyphen.',
                    ),
                    validator: (value) =>
                        RegExp(r'^[A-Za-z0-9_-]{1,30}$')
                            .hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Enter a valid code.',
                  ),
                ],
                if (widget.tab > 0 && hasParents)
                  DropdownButtonFormField<int>(
                    initialValue: _parentId,
                    decoration: InputDecoration(
                      labelText: widget.tab == 1 ? 'Department' : 'Programme',
                    ),
                    items: widget.tab == 1
                        ? [
                            for (final department in widget.catalog.departments)
                              DropdownMenuItem(
                                value: department.id,
                                child: Text(
                                  department.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ]
                        : [
                            for (final programme in widget.catalog.programmes)
                              DropdownMenuItem(
                                value: programme.id,
                                child: Text(
                                  programme.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                    onChanged: widget.item == null
                        ? (value) => setState(() => _parentId = value)
                        : null,
                    validator: (value) =>
                        value == null ? 'Choose an option.' : null,
                  )
                else if (widget.tab > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Add a parent catalog entry first.'),
                  ),
                if (widget.tab == 2) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _level,
                    decoration: const InputDecoration(
                      labelText: 'Degree level',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'DIPLOMA',
                        child: Text('Diploma'),
                      ),
                      DropdownMenuItem(
                        value: 'BACHELOR',
                        child: Text('Bachelor'),
                      ),
                      DropdownMenuItem(value: 'MASTER', child: Text('Master')),
                      DropdownMenuItem(
                        value: 'DOCTORATE',
                        child: Text('Doctorate'),
                      ),
                    ],
                    onChanged: widget.item == null
                        ? (value) => setState(() => _level = value ?? _level)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _numberField(_duration, 'Duration (years)'),
                  Row(
                    children: [
                      Expanded(child: _numberField(_minimumYear, 'First year')),
                      const SizedBox(width: 12),
                      Expanded(child: _numberField(_maximumYear, 'Last year')),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active option'),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
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
          onPressed: hasParents || widget.tab == 0 ? _submit : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
