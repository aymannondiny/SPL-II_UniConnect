class ProjectApplication {
  const ProjectApplication({
    required this.id,
    required this.projectId,
    required this.applicantUserId,
    required this.applicantDisplayName,
    required this.message,
    required this.status,
    required this.appliedAt,
    required this.respondedAt,
  });

  final int id;
  final int projectId;
  final int applicantUserId;
  final String applicantDisplayName;
  final String? message;
  final String status;
  final String appliedAt;
  final String? respondedAt;

  factory ProjectApplication.fromJson(Map<String, dynamic> json) =>
      ProjectApplication(
        id: (json['id'] as num).toInt(),
        projectId: (json['projectId'] as num).toInt(),
        applicantUserId: (json['applicantUserId'] as num).toInt(),
        applicantDisplayName:
            json['applicantDisplayName'] as String? ?? 'UniConnect student',
        message: json['message'] as String?,
        status: json['status'] as String? ?? 'PENDING',
        appliedAt: json['appliedAt'] as String? ?? '',
        respondedAt: json['respondedAt'] as String?,
      );
}
