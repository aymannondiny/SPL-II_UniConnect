part of 'administration_page.dart';

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
