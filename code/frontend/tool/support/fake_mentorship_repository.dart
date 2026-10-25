import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/create_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile.dart';
import 'package:uniconnect/features/mentorship/model/mentor_registration_request.dart';
import 'package:uniconnect/features/mentorship/model/mentor_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_filter_params.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/model/update_slot_request.dart';

/// Explicit visual QA and widget-test fixture; never used by main.dart.
class StubMentorshipRepository implements MentorshipRepository {
  UpdateSlotRequest? lastUpdate;
  List<MentorSummary> mentors = [
    const MentorSummary(
      mentorProfileId: 1,
      userId: 10,
      fullName: 'Ayesha Siddika',
      role: 'STUDENT',
      departmentName: 'Computer Science',
      yearOfStudy: 3,
      status: MentorStatus.available,
      expertiseTopics: ['Algorithms', 'Java'],
    ),
  ];

  List<MentorshipSlotSummary> slots = [
    const MentorshipSlotSummary(
      slotId: 101,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Ayesha Siddika',
      topic: 'Dynamic Programming Masterclass',
      description: 'Understanding memoization and tabulation.',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-10-30',
      startTime: '16:00:00',
      endTime: '17:30:00',
      mode: SlotMode.online,
      capacity: 6,
      currentMenteeCount: 2,
      status: SlotStatus.open,
    ),
  ];

  @override
  Future<MentorshipPageResult<MentorSummary>> browseMentors(
    MentorFilterParams params,
  ) async {
    return MentorshipPageResult(
      items: mentors,
      page: params.page,
      size: params.size,
      totalElements: mentors.length,
    );
  }

  @override
  Future<MentorProfile> getMentorProfile(int mentorProfileId) async {
    return const MentorProfile(
      mentorProfileId: 1,
      userId: 10,
      fullName: 'Ayesha Siddika',
      role: 'STUDENT',
      mentoringBio: 'Experienced mentor',
      status: MentorStatus.available,
      expertise: [],
    );
  }

  @override
  Future<MentorProfile> getMyMentorProfile() async {
    return const MentorProfile(
      mentorProfileId: 1,
      userId: 10,
      fullName: 'Ayesha Siddika',
      role: 'STUDENT',
      mentoringBio: 'Experienced mentor',
      status: MentorStatus.available,
      expertise: [],
    );
  }

  @override
  Future<MentorProfile> registerAsMentor(
    MentorRegistrationRequest request,
  ) async {
    return const MentorProfile(
      mentorProfileId: 1,
      userId: 10,
      fullName: 'Ayesha Siddika',
      role: 'STUDENT',
      mentoringBio: 'Registered mentor',
      status: MentorStatus.available,
      expertise: [],
    );
  }

  @override
  Future<MentorProfile> updateMentorStatus(MentorStatus status) async {
    return MentorProfile(
      mentorProfileId: 1,
      userId: 10,
      fullName: 'Ayesha Siddika',
      role: 'STUDENT',
      mentoringBio: 'Updated mentor',
      status: status,
      expertise: [],
    );
  }

  @override
  Future<MentorshipPageResult<MentorshipSlotSummary>> browseSlots(
    SlotFilterParams params,
  ) async {
    return MentorshipPageResult(
      items: slots,
      page: params.page,
      size: params.size,
      totalElements: slots.length,
    );
  }

  @override
  Future<MentorshipSlot> getSlotDetails(int slotId) async {
    return const MentorshipSlot(
      slotId: 101,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Ayesha Siddika',
      topic: 'Dynamic Programming Masterclass',
      description: 'Understanding memoization and tabulation.',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-10-30',
      startTime: '16:00:00',
      endTime: '17:30:00',
      mode: SlotMode.online,
      capacity: 6,
      currentMenteeCount: 2,
      status: SlotStatus.open,
    );
  }

  @override
  Future<MentorshipSlot> createSlot(CreateSlotRequest request) async {
    return MentorshipSlot(
      slotId: 102,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Ayesha Siddika',
      topic: request.topic,
      description: request.description,
      scheduleType: request.scheduleType,
      startDate: request.startDate,
      startTime: request.startTime,
      endTime: request.endTime,
      mode: request.mode,
      capacity: request.capacity,
      currentMenteeCount: 0,
      status: SlotStatus.open,
    );
  }

  @override
  Future<MentorshipSlot> updateSlot(
    int slotId,
    UpdateSlotRequest request,
  ) async {
    lastUpdate = request;
    return MentorshipSlot(
      slotId: slotId,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Ayesha Siddika',
      topic: request.topic,
      description: request.description,
      scheduleType: request.scheduleType,
      startDate: request.startDate,
      startTime: request.startTime,
      endTime: request.endTime,
      mode: request.mode,
      capacity: request.capacity,
      currentMenteeCount: 2,
      status: SlotStatus.open,
    );
  }

  @override
  Future<MentorshipEnrollment> joinSlot(
    int slotId,
    EnrollSlotRequest request,
  ) async {
    return MentorshipEnrollment(
      enrollmentId: 88,
      slotId: slotId,
      slotTopic: 'Dynamic Programming Masterclass',
      menteeId: 25,
      menteeName: 'Student Mentee',
      status: EnrollmentStatus.active,
    );
  }

  @override
  Future<MentorshipEnrollment> leaveSlot(int slotId) async {
    return MentorshipEnrollment(
      enrollmentId: 88,
      slotId: slotId,
      slotTopic: 'Dynamic Programming Masterclass',
      menteeId: 25,
      menteeName: 'Student Mentee',
      status: EnrollmentStatus.left,
    );
  }

  @override
  Future<MentorshipSlot> closeSlot(int slotId) async {
    return const MentorshipSlot(
      slotId: 101,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Ayesha Siddika',
      topic: 'Dynamic Programming Masterclass',
      description: 'Understanding memoization and tabulation.',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-10-30',
      startTime: '16:00:00',
      endTime: '17:30:00',
      mode: SlotMode.online,
      capacity: 6,
      currentMenteeCount: 2,
      status: SlotStatus.closed,
    );
  }

  @override
  Future<List<MentorshipEnrollment>> getMyParticipation() async => [
    MentorshipEnrollment(
      enrollmentId: 1,
      slotId: 101,
      slotTopic: 'Dynamic Programming Masterclass',
      menteeId: 1,
      menteeName: 'Test Member',
      status: EnrollmentStatus.left,
      joinedAt: DateTime.utc(2026, 10, 10),
      leftAt: DateTime.utc(2026, 10, 17),
      learningGoal: 'Understand dynamic programming',
    ),
    MentorshipEnrollment(
      enrollmentId: 2,
      slotId: 101,
      slotTopic: 'Dynamic Programming Masterclass',
      menteeId: 1,
      menteeName: 'Test Member',
      status: EnrollmentStatus.active,
      joinedAt: DateTime.utc(2026, 10, 24),
    ),
  ];

  @override
  Future<MentorshipSlot> reopenSlot(int slotId) => getSlotDetails(slotId);

  @override
  Future<MentorshipSlot> cancelSlot(int slotId) async {
    return const MentorshipSlot(
      slotId: 101,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Ayesha Siddika',
      topic: 'Dynamic Programming Masterclass',
      description: 'Understanding memoization and tabulation.',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-10-30',
      startTime: '16:00:00',
      endTime: '17:30:00',
      mode: SlotMode.online,
      capacity: 6,
      currentMenteeCount: 2,
      status: SlotStatus.cancelled,
    );
  }

  @override
  Future<List<MentorshipSlotSummary>> getMyMentoringSlots() async {
    return slots;
  }

  @override
  Future<List<MentorshipSlotSummary>> getMyEnrolledSlots() async {
    return slots;
  }

  @override
  Future<List<MentorshipEnrollment>> getSlotAttendees(int slotId) async {
    return [];
  }
}
