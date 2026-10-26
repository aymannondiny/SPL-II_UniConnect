class ContentReport {
  ContentReport.fromJson(Map<String, dynamic> json)
    : id = (json['id'] as num).toInt(),
      targetType = json['targetType'] as String,
      targetId = (json['targetId'] as num).toInt(),
      label = json['targetLabel'] as String,
      reason = json['reason'] as String,
      status = json['status'] as String,
      resolution = json['resolutionSummary'] as String?,
      reviewerId = (json['reviewerId'] as num?)?.toInt(),
      snapshot = json['targetSnapshot'] as String?,
      internalNotes = json['internalNotes'] as String?,
      action = json['action'] as Map<String, dynamic>?,
      history = (json['history'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

  final int id;
  final String targetType;
  final int targetId;
  final String label;
  final String reason;
  final String status;
  final String? resolution;
  final int? reviewerId;
  final String? snapshot;
  final String? internalNotes;
  final Map<String, dynamic>? action;
  final List<Map<String, dynamic>> history;
}
