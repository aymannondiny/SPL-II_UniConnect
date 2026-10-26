class ProjectRecommendation {
  const ProjectRecommendation({
    required this.userId,
    required this.displayName,
    required this.profilePhotoUrl,
    required this.departmentName,
    required this.matchedRequiredSkills,
    required this.matchedOptionalSkills,
  });

  final int userId;
  final String displayName;
  final String? profilePhotoUrl;
  final String? departmentName;
  final List<String> matchedRequiredSkills;
  final List<String> matchedOptionalSkills;

  factory ProjectRecommendation.fromJson(Map<String, dynamic> json) =>
      ProjectRecommendation(
        userId: (json['userId'] as num).toInt(),
        displayName: json['displayName'] as String? ?? 'UniConnect student',
        profilePhotoUrl: json['profilePhotoUrl'] as String?,
        departmentName: json['departmentName'] as String?,
        matchedRequiredSkills:
            (json['matchedRequiredSkills'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(),
        matchedOptionalSkills:
            (json['matchedOptionalSkills'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(),
      );
}
