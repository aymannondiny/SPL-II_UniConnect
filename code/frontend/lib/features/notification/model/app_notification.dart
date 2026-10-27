class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
    required this.readAt,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final String? referenceType;
  final int? referenceId;
  final DateTime createdAt;
  final DateTime? readAt;
  bool get isRead => readAt != null;

  // Existing account-security alerts apply to administrators too. Member
  // reports, club assignments, projects and mentorship are personal activity.
  bool get administratorRelevant =>
      referenceType == 'USER' &&
      const {'ACCOUNT_SUSPENDED', 'ACCOUNT_REACTIVATED'}.contains(type);

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        referenceType: json['referenceType'] as String?,
        referenceId: (json['referenceId'] as num?)?.toInt(),
        createdAt: _apiDateTime(json['createdAt'] as String),
        readAt: json['readAt'] == null
            ? null
            : _apiDateTime(json['readAt'] as String),
      );

  static DateTime _apiDateTime(String value) {
    final hasOffset = RegExp(r'(?:Z|[+-]\d{2}:\d{2})$').hasMatch(value);
    return DateTime.parse(hasOffset ? value : '${value}Z').toLocal();
  }

  AppNotification markRead([DateTime? at]) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    referenceType: referenceType,
    referenceId: referenceId,
    createdAt: createdAt,
    readAt: readAt ?? at ?? DateTime.now(),
  );
}
