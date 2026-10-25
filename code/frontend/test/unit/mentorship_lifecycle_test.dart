import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_schedule_label.dart';
import 'package:uniconnect/features/mentorship/model/create_slot_request.dart';

void main() {
  Map<String, dynamic> slotJson() => {
    'slotId': 1,
    'mentorProfileId': 2,
    'mentorUserId': 3,
    'status': 'COMPLETED',
    'capacity': 5,
    'currentMenteeCount': 1,
    'enrollmentOpen': false,
    'vacancies': 4,
    'meetingCount': 8,
    'nextOccurrenceStartsAt': '2026-11-01T14:00:00',
  };

  test('completed and unfamiliar statuses never become joinable', () {
    for (final status in ['COMPLETED', 'FUTURE_STATUS']) {
      final json = slotJson()..['status'] = status;
      expect(MentorshipSlotSummary.fromJson(json).isOpen, isFalse);
      expect(MentorshipSlot.fromJson(json).isOpen, isFalse);
    }
    expect(SlotStatusX.fromApi('COMPLETED'), SlotStatus.completed);
    expect(EnrollmentStatusX.fromApi('COMPLETED'), EnrollmentStatus.completed);
    expect(EnrollmentStatusX.fromApi('REMOVED'), EnrollmentStatus.removed);
    expect(
      EnrollmentStatusX.fromApi('FUTURE_STATUS'),
      EnrollmentStatus.unknown,
    );
  });

  test('server enrollment closure and vacancies survive serialization', () {
    final json = slotJson()..['status'] = 'OPEN';
    final slot = MentorshipSlotSummary.fromJson(json);
    expect(slot.isOpen, isFalse);
    expect(slot.availableSeats, 4);
    final copy = MentorshipSlotSummary.fromJson(slot.toJson());
    expect(copy.meetingCount, 8);
    expect(copy.enrollmentOpen, isFalse);
    expect(copy.nextOccurrenceStartsAt, DateTime(2026, 11, 1, 14));
  });

  test('persisted occurrences retain cancellation and lifecycle flags', () {
    final json = slotJson()
      ..['occurrenceDetails'] = [
        {
          'occurrenceId': 10,
          'startsAt': '2026-11-01T14:00:00',
          'endsAt': '2026-11-01T15:00:00',
          'cancelledAt': '2026-10-25T12:00:00',
          'ongoing': false,
          'future': true,
        },
      ];
    final slot = MentorshipSlot.fromJson(json);
    expect(slot.occurrenceDetails.single.label, 'Cancelled');
    expect(
      MentorshipSlot.fromJson(slot.toJson())
          .occurrenceDetails
          .single
          .occurrenceId,
      10,
    );
  });

  test(
    'ongoing meeting takes priority over next without device conversion',
    () {
      final label = mentorshipScheduleLabel(
        schedule: 'Weekly',
        startDate: '2026-10-01',
        startTime: '09:00:00',
        ongoing: DateTime(2026, 10, 25, 14),
        next: DateTime(2026, 11, 1, 14),
      );
      expect(label, 'Ongoing: 2026-10-25 at 14:00 · Asia/Dhaka');
    },
  );

  test('finite recurring requests serialize the selected count', () {
    const request = CreateSlotRequest(
      topic: 'Algorithms',
      description: 'Practice graph algorithms',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-11-01',
      startTime: '14:00:00',
      endTime: '15:00:00',
      mode: SlotMode.inPerson,
      location: 'Room 302',
      capacity: 5,
      meetingCount: 8,
    );
    expect(request.validate(), isNull);
    expect(request.toJson()['meetingCount'], 8);
  });
}
