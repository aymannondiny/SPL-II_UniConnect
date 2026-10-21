import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';

@immutable
class MentorshipSlotSummary {
  const MentorshipSlotSummary({
    required this.slotId,
    required this.mentorProfileId,
    required this.mentorUserId,
    required this.mentorName,
    required this.topic,
    required this.description,
    required this.scheduleType,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    required this.mode,
    this.location,
    this.meetingLink,
    required this.capacity,
    required this.currentMenteeCount,
    required this.status,
  });

  final int slotId;
  final int mentorProfileId;
  final int mentorUserId;
  final String mentorName;
  final String topic;
  final String description;
  final ScheduleType scheduleType;
  final String startDate;
  final String startTime;
  final String endTime;
  final SlotMode mode;
  final String? location;
  final String? meetingLink;
  final int capacity;
  final int currentMenteeCount;
  final SlotStatus status;

  bool get isFull => currentMenteeCount >= capacity;
  bool get isOpen => status == SlotStatus.open && !isFull;
  int get availableSeats => (capacity - currentMenteeCount).clamp(0, capacity);

  factory MentorshipSlotSummary.fromJson(Map<String, dynamic> json) {
    return MentorshipSlotSummary(
      slotId: (json['slotId'] as num).toInt(),
      mentorProfileId: (json['mentorProfileId'] as num).toInt(),
      mentorUserId: (json['mentorUserId'] as num).toInt(),
      mentorName: json['mentorName'] as String? ?? 'Mentor',
      topic: json['topic'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scheduleType: ScheduleTypeX.fromApi(json['scheduleType'] as String?),
      startDate: json['startDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      mode: SlotModeX.fromApi(json['mode'] as String?),
      location: json['location'] as String?,
      meetingLink: json['meetingLink'] as String?,
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      currentMenteeCount: (json['currentMenteeCount'] as num?)?.toInt() ?? 0,
      status: SlotStatusX.fromApi(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'mentorProfileId': mentorProfileId,
    'mentorUserId': mentorUserId,
    'mentorName': mentorName,
    'topic': topic,
    'description': description,
    'scheduleType': scheduleType.toApi(),
    'startDate': startDate,
    'startTime': startTime,
    'endTime': endTime,
    'mode': mode.toApi(),
    'location': location,
    'meetingLink': meetingLink,
    'capacity': capacity,
    'currentMenteeCount': currentMenteeCount,
    'status': status.toApi(),
  };
}
