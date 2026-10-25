class ProjectAuditEntry {
  const ProjectAuditEntry({
    required this.id,
    required this.actorUserId,
    required this.applicationId,
    required this.eventType,
    required this.occurredAt,
  });

  final int id;
  final int? actorUserId;
  final int? applicationId;
  final String eventType;
  final String occurredAt;

  factory ProjectAuditEntry.fromJson(Map<String, dynamic> json) =>
      ProjectAuditEntry(
        id: (json['id'] as num).toInt(),
        actorUserId: (json['actorUserId'] as num?)?.toInt(),
        applicationId: (json['applicationId'] as num?)?.toInt(),
        eventType: json['eventType'] as String? ?? 'UPDATED',
        occurredAt: json['occurredAt'] as String? ?? '',
      );
}
