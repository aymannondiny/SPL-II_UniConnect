class ProjectCandidateSkill {
  const ProjectCandidateSkill({required this.name, required this.kind});

  final String name;
  final String kind;

  factory ProjectCandidateSkill.fromJson(Map<String, dynamic> json) =>
      ProjectCandidateSkill(
        name: json['name'] as String? ?? 'Skill',
        kind: json['kind'] as String? ?? 'REQUIRED',
      );
}
