import 'package:flutter/material.dart';

import '../../data/connection_repository.dart';
import '../../model/member_filters.dart';

/// Owns filter input and validation without coupling it to search results.
class MemberFilterPanel extends StatefulWidget {
  const MemberFilterPanel({
    required this.repository,
    required this.onApply,
    super.key,
  });
  final ConnectionRepository repository;
  final ValueChanged<MemberFilters> onApply;
  @override
  State<MemberFilterPanel> createState() => _MemberFilterPanelState();
}

class _MemberFilterPanelState extends State<MemberFilterPanel> {
  final _form = GlobalKey<FormState>();
  final _skills = TextEditingController();
  final _company = TextEditingController();
  final _year = TextEditingController();
  String _role = '';
  String _department = '';
  List<Map<String, dynamic>> _departments = [];
  bool _loadingCatalog = false;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCatalog = true;
      _catalogError = null;
    });
    try {
      final catalog = await widget.repository.catalog();
      if (!mounted) return;
      setState(() {
        _departments = (catalog['departments'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        _loadingCatalog = false;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _loadingCatalog = false;
          _catalogError = 'Departments could not be loaded.';
        });
      }
    }
  }

  @override
  void dispose() {
    _skills.dispose();
    _company.dispose();
    _year.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_form.currentState!.validate()) return;
    widget.onApply(
      MemberFilters(
        role: _role,
        departmentId: _department,
        skills: _skills.text,
        company: _company.text,
        graduationYear: _year.text.trim(),
      ),
    );
  }

  void _reset() {
    _skills.clear();
    _company.clear();
    _year.clear();
    setState(() {
      _role = '';
      _department = '';
    });
    _form.currentState!.reset();
    widget.onApply(const MemberFilters());
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: ExpansionTile(
      key: const PageStorageKey<String>('member-filter-panel'),
      title: const Text('Filter people'),
      leading: const Icon(Icons.tune),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _form,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 600
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('role-$_role'),
                          initialValue: _role,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Member role',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '',
                              child: Text('All members'),
                            ),
                            DropdownMenuItem(
                              value: 'STUDENT',
                              child: Text('Students'),
                            ),
                            DropdownMenuItem(
                              value: 'ALUMNI',
                              child: Text('Alumni'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _role = value ?? ''),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'department-$_department-${_departments.length}',
                          ),
                          initialValue: _department,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _loadingCatalog
                                ? 'Loading departments…'
                                : 'Department',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All departments'),
                            ),
                            for (final department in _departments)
                              DropdownMenuItem(
                                value: '${department['id']}',
                                child: Text('${department['name']}'),
                              ),
                          ],
                          onChanged: _loadingCatalog
                              ? null
                              : (value) =>
                                    setState(() => _department = value ?? ''),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: TextFormField(
                          key: const PageStorageKey<String>(
                            'member-filter-skills',
                          ),
                          controller: _skills,
                          decoration: const InputDecoration(
                            labelText: 'Skills',
                            hintText: 'Flutter, Java',
                          ),
                          validator: (value) {
                            final skills = (value ?? '')
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty);
                            return skills.length > 10 ||
                                    skills.any((s) => s.length > 60)
                                ? 'Use up to 10 skills, each up to 60 characters.'
                                : null;
                          },
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: TextFormField(
                          key: const PageStorageKey<String>(
                            'member-filter-company',
                          ),
                          controller: _company,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            counterText: '',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: TextFormField(
                          key: const PageStorageKey<String>(
                            'member-filter-year',
                          ),
                          controller: _year,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Graduation year',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final year = int.tryParse(value.trim());
                            return year == null || year < 1900 || year > 2200
                                ? 'Enter a year from 1900 to 2200.'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_catalogError != null)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(_catalogError!),
                        TextButton(
                          onPressed: _loadCatalog,
                          child: const Text('Retry departments'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _apply,
                        child: const Text('Apply filters'),
                      ),
                      TextButton(
                        onPressed: _reset,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
