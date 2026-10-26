import 'project_form_validation.dart';

/// The submitted search, kept stable while the next page is requested.
class ProjectCandidateQuery {
  const ProjectCandidateQuery({
    required this.requiredSkills,
    required this.optionalSkills,
    this.departmentId,
    this.projectAvailable,
  });

  final List<String> requiredSkills;
  final List<String> optionalSkills;
  final int? departmentId;
  final bool? projectAvailable;

  static List<String> parseSkills(String value) => value
      .split(',')
      .map(ProjectFormValidation.normalizeSkill)
      .where((skill) => skill.isNotEmpty)
      .toSet()
      .toList(growable: false);
}
