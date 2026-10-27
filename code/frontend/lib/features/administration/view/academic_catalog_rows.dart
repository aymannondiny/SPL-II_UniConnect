part of 'administration_page.dart';

extension _AcademicCatalogRows on _AdministrationPageState {
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
}
