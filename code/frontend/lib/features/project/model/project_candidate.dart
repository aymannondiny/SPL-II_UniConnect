import 'project_candidate_skill.dart';

class ProjectCandidate {
  const ProjectCandidate({
    required this.userId,
    required this.fullName,
    required this.profilePhotoUrl,
    required this.departmentName,
    required this.programmeName,
    required this.yearOfStudy,
    required this.projectAvailable,
    required this.skills,
    required this.connectionStatus,
  });

  final int userId;
  final String fullName;
  final String? profilePhotoUrl;
  final String? departmentName;
  final String? programmeName;
  final int? yearOfStudy;
  final bool? projectAvailable;
  final List<ProjectCandidateSkill> skills;
  final String? connectionStatus;

  factory ProjectCandidate.fromJson(Map<String, dynamic> json) {
    final department = json['department'] as Map<String, dynamic>?;
    final programme = json['programme'] as Map<String, dynamic>?;
    final connection = json['connection'] as Map<String, dynamic>?;
    return ProjectCandidate(
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String? ?? 'UniConnect student',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      departmentName: department?['name'] as String?,
      programmeName: programme?['name'] as String?,
      yearOfStudy: (json['yearOfStudy'] as num?)?.toInt(),
      projectAvailable: json['projectAvailable'] as bool?,
      skills: (json['relevantSkills'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProjectCandidateSkill.fromJson)
          .toList(),
      connectionStatus: connection?['status'] as String?,
    );
  }
}
