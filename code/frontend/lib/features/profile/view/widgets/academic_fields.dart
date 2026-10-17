import 'package:flutter/material.dart';
import 'package:uniconnect/features/profile/model/academic_catalog.dart';

/// Dependent department/programme/degree selectors never invent catalog IDs.
class AcademicFields extends StatelessWidget {
  const AcademicFields({
    required this.catalog,
    required this.department,
    required this.programme,
    required this.degree,
    required this.onDepartment,
    required this.onProgramme,
    required this.onDegree,
    super.key,
  });
  final AcademicCatalog catalog;
  final int? department;
  final int? programme;
  final int? degree;
  final ValueChanged<int?> onDepartment;
  final ValueChanged<int?> onProgramme;
  final ValueChanged<int?> onDegree;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _select(
        'Department',
        department,
        catalog.departments.where(
          (d) => catalog.programmes.any(
            (p) =>
                p.parentId == d.id &&
                catalog.degrees.any((degree) => degree.parentId == p.id),
          ),
        ),
        onDepartment,
      ),
      _select(
        'Programme',
        programme,
        catalog.programmes.where(
          (p) =>
              p.parentId == department &&
              catalog.degrees.any((d) => d.parentId == p.id),
        ),
        onProgramme,
      ),
      _select(
        'Degree',
        degree,
        catalog.degrees.where((d) => d.parentId == programme),
        onDegree,
      ),
    ],
  );
  Widget _select(
    String label,
    int? value,
    Iterable<AcademicOption> options,
    ValueChanged<int?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: DropdownButtonFormField<int>(
      key: ValueKey('$label-$value-${options.map((o) => o.id).join(',')}'),
      initialValue: options.any((o) => o.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option.id,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: options.isEmpty ? null : changed,
      validator: (value) => value == null ? 'Select $label.' : null,
    ),
  );
}
