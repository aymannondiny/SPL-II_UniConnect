import 'publication_time.dart';

class ClubEvent {
  const ClubEvent({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    this.location,
    this.registrationUrl,
    this.registrationDeadline,
  });

  final int id;
  final int clubId;
  final String clubName;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? location;
  final String? registrationUrl;
  final DateTime? registrationDeadline;

  String timingAt(DateTime now) => now.isBefore(startsAt)
      ? 'Upcoming'
      : now.isAfter(endsAt)
      ? 'Past'
      : 'Live now';

  Uri? registrationAt(DateTime now) {
    if (now.isAfter(endsAt) ||
        (registrationDeadline != null &&
            !now.isBefore(registrationDeadline!))) {
      return null;
    }
    final uri = Uri.tryParse(registrationUrl ?? '');
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }

  factory ClubEvent.fromJson(Map<String, dynamic> json) => ClubEvent(
    id: (json['id'] as num).toInt(),
    clubId: (json['clubId'] as num).toInt(),
    clubName: json['clubName'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    startsAt: publicationTime(json['startsAt'] as String),
    endsAt: publicationTime(json['endsAt'] as String),
    location: json['location'] as String?,
    registrationUrl: json['registrationUrl'] as String?,
    registrationDeadline: json['registrationDeadline'] == null
        ? null
        : publicationTime(json['registrationDeadline'] as String),
  );
}
