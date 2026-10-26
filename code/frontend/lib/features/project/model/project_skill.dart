class ProjectSkill {
  const ProjectSkill({
    required this.id,
    required this.name,
    required this.isRequired,
  });

  final int id;
  final String name;
  final bool isRequired;

  factory ProjectSkill.fromJson(Map<String, dynamic> json) => ProjectSkill(
    id: ((json['id'] ?? json['skillId']) as num).toInt(),
    name: json['name'] as String? ?? 'Skill',
    isRequired: json['required'] as bool? ?? false,
  );
}
