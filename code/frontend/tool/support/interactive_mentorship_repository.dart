import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile_missing.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';

import 'fake_mentorship_repository.dart';

/// In-memory enrollment demo, isolated from production and legacy test fixtures.
class InteractiveMentorshipRepository extends StubMentorshipRepository {
  final Set<int> _joined = {};
  final List<MentorshipEnrollment> _history = [];

  @override
  Future<MentorProfile> getMyMentorProfile() async =>
      throw const MentorProfileMissing();

  @override
  Future<List<MentorshipSlotSummary>> getMyMentoringSlots() async => [];

  @override
  Future<List<MentorshipSlotSummary>> getMyEnrolledSlots() async =>
      slots.where((slot) => _joined.contains(slot.slotId)).toList();

  @override
  Future<List<MentorshipEnrollment>> getMyParticipation() async =>
      List.of(_history);

  Map<String, dynamic> _data(MentorshipSlotSummary slot, {int? count}) => {
    'slotId': slot.slotId,
    'mentorProfileId': slot.mentorProfileId,
    'mentorUserId': slot.mentorUserId,
    'mentorName': slot.mentorName,
    'topic': slot.topic,
    'description': slot.description,
    'scheduleType': slot.scheduleType.toApi(),
    'startDate': slot.startDate,
    'startTime': slot.startTime,
    'endTime': slot.endTime,
    'mode': slot.mode.toApi(),
    'location': slot.location,
    'meetingLink': slot.meetingLink,
    'capacity': slot.capacity,
    'currentMenteeCount': count ?? slot.currentMenteeCount,
    'status': (count ?? slot.currentMenteeCount) >= slot.capacity
        ? 'FULL'
        : slot.status.toApi(),
    'enrollmentOpen': slot.enrollmentOpen,
  };

  @override
  Future<MentorshipSlot> getSlotDetails(int slotId) async =>
      MentorshipSlot.fromJson(
        _data(slots.firstWhere((slot) => slot.slotId == slotId)),
      );

  @override
  Future<MentorshipEnrollment> joinSlot(
    int slotId,
    EnrollSlotRequest request,
  ) async {
    final index = slots.indexWhere((slot) => slot.slotId == slotId);
    if (index < 0) throw const AuthFailure('Session is unavailable.');
    final slot = slots[index];
    if (_joined.contains(slotId)) {
      throw const AuthFailure('You already joined this session.');
    }
    if (!slot.isOpen) {
      throw const AuthFailure(
        'This session is no longer accepting enrollment.',
      );
    }
    _joined.add(slotId);
    slots[index] = MentorshipSlotSummary.fromJson(
      _data(slot, count: slot.currentMenteeCount + 1),
    );
    final enrollment = MentorshipEnrollment(
      enrollmentId: _history.length + 1,
      slotId: slotId,
      slotTopic: slot.topic,
      menteeId: 1,
      menteeName: 'Test Member',
      status: EnrollmentStatus.active,
      joinedAt: DateTime.now().toUtc(),
      joinMessage: request.joinMessage,
      learningGoal: request.learningGoal,
    );
    _history.insert(0, enrollment);
    return enrollment;
  }

  @override
  Future<MentorshipEnrollment> leaveSlot(int slotId) async {
    if (!_joined.remove(slotId)) {
      throw const AuthFailure('You are not enrolled.');
    }
    final index = slots.indexWhere((slot) => slot.slotId == slotId);
    final slot = slots[index];
    final data = _data(slot, count: slot.currentMenteeCount - 1);
    if (slot.status == SlotStatus.full) data['status'] = 'OPEN';
    slots[index] = MentorshipSlotSummary.fromJson(data);
    final period = _history.indexWhere(
      (item) => item.slotId == slotId && item.status == EnrollmentStatus.active,
    );
    final previous = _history[period];
    final left = MentorshipEnrollment(
      enrollmentId: previous.enrollmentId,
      slotId: slotId,
      slotTopic: slot.topic,
      menteeId: 1,
      menteeName: 'Test Member',
      status: EnrollmentStatus.left,
      joinedAt: previous.joinedAt,
      leftAt: DateTime.now().toUtc(),
      joinMessage: previous.joinMessage,
      learningGoal: previous.learningGoal,
    );
    _history[period] = left;
    return left;
  }
}
