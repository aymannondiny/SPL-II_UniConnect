class ProjectBrowseFilters {
  const ProjectBrowseFilters({
    this.skill = '',
    this.availability = '',
    this.sort = 'CREATED_DESC',
    this.departmentId,
  });

  final String skill;
  final String availability;
  final String sort;
  final int? departmentId;

  ProjectBrowseFilters copyWith({
    String? skill,
    String? availability,
    String? sort,
    int? departmentId,
    bool clearDepartment = false,
  }) => ProjectBrowseFilters(
    skill: skill ?? this.skill,
    availability: availability ?? this.availability,
    sort: sort ?? this.sort,
    departmentId: clearDepartment ? null : departmentId ?? this.departmentId,
  );

  Map<String, String> get query => {
    if (skill.trim().isNotEmpty) 'skill': skill.trim(),
    if (availability.isNotEmpty) 'availability': availability,
    if (departmentId != null) 'departmentId': '$departmentId',
    'sort': sort,
    'page': '0',
    'size': '20',
  };
}
