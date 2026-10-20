class ClubWorkspaceContext {
  const ClubWorkspaceContext({
    required this.contextType,
    this.assignmentId,
    this.clubId,
    this.clubName,
    this.clubRole,
  });
  final String contextType;
  final int? assignmentId;
  final int? clubId;
  final String? clubName;
  final String? clubRole;

  factory ClubWorkspaceContext.fromJson(Map<String, dynamic> json) =>
      ClubWorkspaceContext(
        contextType: json['contextType'] as String,
        assignmentId: (json['assignmentId'] as num?)?.toInt(),
        clubId: (json['clubId'] as num?)?.toInt(),
        clubName: json['clubName'] as String?,
        clubRole: json['clubRole'] as String?,
      );
}
