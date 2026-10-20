import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';

@immutable
class MentorshipEnrollment {
  const MentorshipEnrollment({
    required this.enrollmentId,
    required this.slotId,
    required this.slotTopic,
    required this.menteeId,
    required this.menteeName,
    this.joinMessage,
    this.learningGoal,
    required this.status,
    this.joinedAt,
    this.leftAt,
  });

  final int enrollmentId;
  final int slotId;
  final String slotTopic;
  final int menteeId;
  final String menteeName;
  final String? joinMessage;
  final String? learningGoal;
  final EnrollmentStatus status;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  bool get isActive => status == EnrollmentStatus.active;

  factory MentorshipEnrollment.fromJson(Map<String, dynamic> json) {
    return MentorshipEnrollment(
      enrollmentId: (json['enrollmentId'] as num).toInt(),
      slotId: (json['slotId'] as num).toInt(),
      slotTopic: json['slotTopic'] as String? ?? '',
      menteeId: (json['menteeId'] as num).toInt(),
      menteeName: json['menteeName'] as String? ?? 'Mentee',
      joinMessage: json['joinMessage'] as String?,
      learningGoal: json['learningGoal'] as String?,
      status: EnrollmentStatusX.fromApi(json['status'] as String?),
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String)
          : null,
      leftAt: json['leftAt'] != null
          ? DateTime.tryParse(json['leftAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'enrollmentId': enrollmentId,
    'slotId': slotId,
    'slotTopic': slotTopic,
    'menteeId': menteeId,
    'menteeName': menteeName,
    'joinMessage': joinMessage,
    'learningGoal': learningGoal,
    'status': status.toApi(),
    if (joinedAt != null) 'joinedAt': joinedAt!.toIso8601String(),
    if (leftAt != null) 'leftAt': leftAt!.toIso8601String(),
  };
}
