class ProjectDepartment {
  const ProjectDepartment({
    required this.id,
    required this.name,
    required this.code,
  });
  final int id;
  final String name;
  final String code;

  factory ProjectDepartment.fromJson(Map<String, dynamic> json) =>
      ProjectDepartment(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? 'Department',
        code: json['code'] as String? ?? '',
      );
}
