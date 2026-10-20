import 'publication_time.dart';

class ClubAnnouncement {
  const ClubAnnouncement({
    required this.id,
    required this.clubName,
    required this.title,
    required this.content,
    required this.priority,
    this.publishedAt,
    this.status = 'PUBLISHED',
    this.expiresAt,
  });

  final int id;
  final String clubName;
  final String title;
  final String content;
  final String priority;
  final DateTime? publishedAt;
  final String status;
  final DateTime? expiresAt;

  factory ClubAnnouncement.fromJson(Map<String, dynamic> json) =>
      ClubAnnouncement(
        id: (json['id'] as num).toInt(),
        clubName: json['clubName'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        priority: json['priority'] as String,
        publishedAt: json['publishedAt'] == null
            ? null
            : publicationTime(json['publishedAt'] as String),
        status: json['status'] as String? ?? 'PUBLISHED',
        expiresAt: json['expiresAt'] == null
            ? null
            : publicationTime(json['expiresAt'] as String),
      );
}
