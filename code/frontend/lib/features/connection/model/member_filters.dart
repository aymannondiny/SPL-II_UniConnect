/// Immutable search criteria; only supported, nonempty parameters reach REST.
class MemberFilters {
  const MemberFilters({
    this.name = '',
    this.role = '',
    this.departmentId = '',
    this.skills = '',
    this.company = '',
    this.graduationYear = '',
    this.sort = 'NAME_ASC',
  });
  final String name;
  final String role;
  final String departmentId;
  final String skills;
  final String company;
  final String graduationYear;
  final String sort;

  Map<String, String> get query => {
    'sort': sort,
    if (name.isNotEmpty) 'name': name,
    if (role.isNotEmpty) 'role': role,
    if (departmentId.isNotEmpty) 'departmentId': departmentId,
    if (skills.trim().isNotEmpty)
      'skills': skills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .join(','),
    if (company.trim().isNotEmpty) 'company': company.trim(),
    if (graduationYear.isNotEmpty) 'graduationYear': graduationYear,
  };

  MemberFilters withName(String value) => MemberFilters(
    name: value,
    role: role,
    departmentId: departmentId,
    skills: skills,
    company: company,
    graduationYear: graduationYear,
    sort: sort,
  );
}
