import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';

@immutable
class UpdateSlotRequest {
  const UpdateSlotRequest({
    required this.topic,
    required this.description,
    required this.scheduleType,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    this.recurrenceEndDate,
    required this.mode,
    this.location,
    this.meetingLink,
    required this.capacity,
  });

  final String topic;
  final String description;
  final ScheduleType scheduleType;
  final String startDate;
  final String startTime;
  final String endTime;
  final String? recurrenceEndDate;
  final SlotMode mode;
  final String? location;
  final String? meetingLink;
  final int capacity;

  String? validate() {
    final t = topic.trim();
    if (t.length < 2 || t.length > 200) {
      return 'Topic must be between 2 and 200 characters.';
    }
    final d = description.trim();
    if (d.length < 5 || d.length > 2000) {
      return 'Description must be between 5 and 2000 characters.';
    }
    if (startDate.trim().isEmpty) {
      return 'Start date is required.';
    }
    if (startTime.trim().isEmpty || endTime.trim().isEmpty) {
      return 'Start and end times are required.';
    }
    if (capacity < 1 || capacity > 50) {
      return 'Capacity must be between 1 and 50 participants.';
    }
    if (mode == SlotMode.online &&
        (meetingLink == null || meetingLink!.trim().isEmpty)) {
      return 'Meeting link is required for online sessions.';
    }
    if (mode == SlotMode.inPerson &&
        (location == null || location!.trim().isEmpty)) {
      return 'Location is required for in-person sessions.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'topic': topic.trim(),
    'description': description.trim(),
    'scheduleType': scheduleType.toApi(),
    'startDate': startDate.trim(),
    'startTime': startTime.trim(),
    'endTime': endTime.trim(),
    if (recurrenceEndDate != null && recurrenceEndDate!.trim().isNotEmpty)
      'recurrenceEndDate': recurrenceEndDate!.trim(),
    'mode': mode.toApi(),
    if (location != null && location!.trim().isNotEmpty)
      'location': location!.trim(),
    if (meetingLink != null && meetingLink!.trim().isNotEmpty)
      'meetingLink': meetingLink!.trim(),
    'capacity': capacity,
  };
}
