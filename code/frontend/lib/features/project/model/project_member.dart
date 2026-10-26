class ProjectMember {
  const ProjectMember({
    required this.membershipId,
    required this.memberUserId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  final int membershipId;
  final int memberUserId;
  final String displayName;
  final String role;
  final String joinedAt;

  factory ProjectMember.fromJson(Map<String, dynamic> json) => ProjectMember(
    membershipId: ((json['id'] ?? json['membershipId']) as num).toInt(),
    memberUserId: ((json['userId'] ?? json['memberUserId']) as num).toInt(),
    displayName: json['displayName'] as String? ?? 'UniConnect student',
    role: json['role'] as String? ?? 'TEAMMATE',
    joinedAt: json['joinedAt'] as String? ?? '',
  );
}
