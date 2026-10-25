import 'package:flutter/foundation.dart';

@immutable
class MentorshipOccurrence {
  const MentorshipOccurrence({
    required this.occurrenceId,
    required this.startsAt,
    required this.endsAt,
    this.cancelledAt,
    required this.ongoing,
    required this.future,
  });

  final int occurrenceId;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime? cancelledAt;
  final bool ongoing;
  final bool future;

  String get label => cancelledAt != null
      ? 'Cancelled'
      : ongoing
      ? 'Ongoing'
      : future
      ? 'Upcoming'
      : 'Past';

  factory MentorshipOccurrence.fromJson(Map<String, dynamic> json) {
    return MentorshipOccurrence(
      occurrenceId: (json['occurrenceId'] as num).toInt(),
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      cancelledAt: DateTime.tryParse(json['cancelledAt'] as String? ?? ''),
      ongoing: json['ongoing'] as bool? ?? false,
      future: json['future'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'occurrenceId': occurrenceId,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'cancelledAt': cancelledAt?.toIso8601String(),
    'ongoing': ongoing,
    'future': future,
  };
}
