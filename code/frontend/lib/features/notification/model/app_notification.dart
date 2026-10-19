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

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        referenceType: json['referenceType'] as String?,
        referenceId: (json['referenceId'] as num?)?.toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
      );

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
