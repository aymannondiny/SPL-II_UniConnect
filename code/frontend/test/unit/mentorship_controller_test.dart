import 'package:uniconnect/features/mentorship/model/mentor_profile_missing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
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

class FakeMentorshipRepository implements MentorshipRepository {
  List<MentorSummary> fakeMentors = [
    const MentorSummary(
      mentorProfileId: 1,
      userId: 10,
      fullName: 'Tahmid Khan',
      role: 'STUDENT',
      departmentName: 'CSE',
      yearOfStudy: 3,
      status: MentorStatus.available,
      expertiseTopics: ['Algorithms', 'Java'],
    ),
  ];

  List<MentorshipSlotSummary> fakeSlots = [
    const MentorshipSlotSummary(
      slotId: 101,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Tahmid Khan',
      topic: 'Algorithms Review',
      description: 'Reviewing graph theory',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-10-25',
      startTime: '10:00:00',
      endTime: '11:00:00',
      mode: SlotMode.online,
      capacity: 5,
      currentMenteeCount: 1,
      status: SlotStatus.open,
    ),
  ];

  MentorProfile? fakeMyProfile;
  List<MentorshipEnrollment> fakeAttendees = [];
  bool throwError = false;

  @override
  Future<MentorshipPageResult<MentorSummary>> browseMentors(
    MentorFilterParams params,
  ) async {
    if (throwError) throw const AuthFailure('Server error');
    return MentorshipPageResult(
      items: fakeMentors,
      page: params.page,
      size: params.size,
      totalElements: fakeMentors.length,
    );
  }

  @override
  Future<MentorProfile> getMentorProfile(int mentorProfileId) async {
    if (throwError) throw const AuthFailure('Server error');
    return fakeMyProfile ??
        const MentorProfile(
          mentorProfileId: 1,
          userId: 10,
          fullName: 'Tahmid Khan',
          role: 'STUDENT',
          mentoringBio: 'Bio text here',
          status: MentorStatus.available,
          expertise: [],
        );
  }

  @override
  Future<MentorProfile> getMyMentorProfile() async {
    if (throwError) {
      throw const AuthFailure('Mentor profile service unavailable');
    }
    if (fakeMyProfile == null) throw const MentorProfileMissing();
    return fakeMyProfile!;
  }

  @override
  Future<MentorProfile> registerAsMentor(
    MentorRegistrationRequest request,
  ) async {
    if (throwError) throw const AuthFailure('Registration failed');
    final profile = MentorProfile(
      mentorProfileId: 2,
      userId: 20,
      fullName: 'New Mentor',
      role: 'STUDENT',
      mentoringBio: request.mentoringBio,
      status: MentorStatus.available,
      expertise: request.expertise
          .map(
            (e) => MentorExpertise(topic: e.topic, description: e.description),
          )
          .toList(),
    );
    fakeMyProfile = profile;
    return profile;
  }

  @override
  Future<MentorProfile> updateMentorStatus(MentorStatus status) async {
    if (throwError) throw const AuthFailure('Update failed');
    fakeMyProfile = MentorProfile(
      mentorProfileId: 2,
      userId: 20,
      fullName: 'New Mentor',
      role: 'STUDENT',
      mentoringBio: 'Bio',
      status: status,
      expertise: [],
    );
    return fakeMyProfile!;
  }

  @override
  Future<MentorshipPageResult<MentorshipSlotSummary>> browseSlots(
    SlotFilterParams params,
  ) async {
    if (throwError) throw const AuthFailure('Server error');
    return MentorshipPageResult(
      items: fakeSlots,
      page: params.page,
      size: params.size,
      totalElements: fakeSlots.length,
    );
  }

  @override
  Future<MentorshipSlot> getSlotDetails(int slotId) async {
    if (throwError) throw const AuthFailure('Slot not found');
    return const MentorshipSlot(
      slotId: 101,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Tahmid Khan',
      topic: 'Algorithms Review',
      description: 'Reviewing graph theory',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-10-25',
      startTime: '10:00:00',
      endTime: '11:00:00',
      mode: SlotMode.online,
      capacity: 5,
      currentMenteeCount: 1,
      status: SlotStatus.open,
    );
  }

  @override
  Future<MentorshipSlot> createSlot(CreateSlotRequest request) async {
    if (throwError) throw const AuthFailure('Create failed');
    return MentorshipSlot(
      slotId: 102,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Tahmid Khan',
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
    if (throwError) throw const AuthFailure('Update failed');
    return MentorshipSlot(
      slotId: slotId,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Tahmid Khan',
      topic: request.topic,
      description: request.description,
      scheduleType: request.scheduleType,
      startDate: request.startDate,
      startTime: request.startTime,
      endTime: request.endTime,
      mode: request.mode,
      capacity: request.capacity,
      currentMenteeCount: 1,
      status: SlotStatus.open,
    );
  }

  @override
  Future<MentorshipEnrollment> joinSlot(
    int slotId,
    EnrollSlotRequest request,
  ) async {
    if (throwError) throw const AuthFailure('Join failed');
    return MentorshipEnrollment(
      enrollmentId: 99,
      slotId: slotId,
      slotTopic: 'Algorithms Review',
      menteeId: 44,
      menteeName: 'Test Mentee',
      status: EnrollmentStatus.active,
    );
  }

  @override
  Future<MentorshipEnrollment> leaveSlot(int slotId) async {
    if (throwError) throw const AuthFailure('Leave failed');
    return MentorshipEnrollment(
      enrollmentId: 99,
      slotId: slotId,
      slotTopic: 'Algorithms Review',
      menteeId: 44,
      menteeName: 'Test Mentee',
      status: EnrollmentStatus.left,
    );
  }

  @override
  Future<MentorshipSlot> closeSlot(int slotId) async {
    if (throwError) throw const AuthFailure('Close failed');
    return const MentorshipSlot(
      slotId: 101,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Tahmid Khan',
      topic: 'Algorithms Review',
      description: 'Reviewing graph theory',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-10-25',
      startTime: '10:00:00',
      endTime: '11:00:00',
      mode: SlotMode.online,
      capacity: 5,
      currentMenteeCount: 1,
      status: SlotStatus.closed,
    );
  }

  @override
  Future<List<MentorshipEnrollment>> getMyParticipation() async => [];

  @override
  Future<MentorshipSlot> reopenSlot(int slotId) => getSlotDetails(slotId);

  @override
  Future<MentorshipSlot> cancelSlot(int slotId) async {
    if (throwError) throw const AuthFailure('Cancel failed');
    return const MentorshipSlot(
      slotId: 101,
      mentorProfileId: 1,
      mentorUserId: 10,
      mentorName: 'Tahmid Khan',
      topic: 'Algorithms Review',
      description: 'Reviewing graph theory',
      scheduleType: ScheduleType.weekly,
      startDate: '2026-10-25',
      startTime: '10:00:00',
      endTime: '11:00:00',
      mode: SlotMode.online,
      capacity: 5,
      currentMenteeCount: 1,
      status: SlotStatus.cancelled,
    );
  }

  @override
  Future<List<MentorshipSlotSummary>> getMyMentoringSlots() async {
    if (throwError) throw const AuthFailure('Error');
    return fakeSlots;
  }

  @override
  Future<List<MentorshipSlotSummary>> getMyEnrolledSlots() async {
    if (throwError) throw const AuthFailure('Error');
    return fakeSlots;
  }

  @override
  Future<List<MentorshipEnrollment>> getSlotAttendees(int slotId) async {
    if (throwError) throw const AuthFailure('Error');
    return fakeAttendees;
  }
}

void main() {
  late FakeMentorshipRepository repository;
  late MentorshipController controller;

  setUp(() {
    repository = FakeMentorshipRepository();
    controller = MentorshipController(repository);
  });

  tearDown(() {
    controller.dispose();
  });

  group('MentorshipController Lifecycle & State Tests', () {
    test('initial state is correct', () {
      expect(controller.activeTab, MentorshipTab.mentors);
      expect(controller.mentors, isEmpty);
      expect(controller.slots, isEmpty);
      expect(controller.myMentoringSlots, isEmpty);
      expect(controller.myEnrolledSlots, isEmpty);
      expect(controller.isRegisteredMentor, false);
      expect(controller.loading, false);
      expect(controller.error, isNull);
    });

    test('loadMentors populates directory and total count', () async {
      await controller.loadMentors();
      expect(controller.mentors.length, 1);
      expect(controller.totalMentors, 1);
      expect(controller.mentors.first.fullName, 'Tahmid Khan');
      expect(controller.mentorsLoading, false);
      expect(controller.error, isNull);
    });

    test(
      'updateMentorFilters updates parameters and triggers reload',
      () async {
        const filters = MentorFilterParams(topic: 'Algorithms');
        controller.updateMentorFilters(filters);
        await Future.delayed(Duration.zero);
        expect(controller.mentorFilters.topic, 'Algorithms');
        expect(controller.mentors.isNotEmpty, true);
      },
    );

    test('loadSlots populates slots list and total count', () async {
      await controller.loadSlots();
      expect(controller.slots.length, 1);
      expect(controller.totalSlots, 1);
      expect(controller.slots.first.topic, 'Algorithms Review');
      expect(controller.slotsLoading, false);
    });

    test('loadMySessions populates mentoring and enrolled slots', () async {
      await controller.loadMySessions();
      expect(controller.myMentoringSlots.length, 1);
      expect(controller.myEnrolledSlots.length, 1);
      expect(controller.sessionsLoading, false);
    });

    test('loadMyProfile handles unregistered mentor gracefully', () async {
      await controller.loadMyProfile();
      expect(controller.isRegisteredMentor, false);
      expect(controller.myProfile, isNull);
      expect(controller.error, isNull);
    });

    test('registerMentor updates profile and mentor status', () async {
      const request = MentorRegistrationRequest(
        mentoringBio: 'Experienced senior student eager to mentor.',
        expertise: [MentorExpertiseInput(topic: 'Flutter')],
      );
      final success = await controller.registerMentor(request);
      expect(success, true);
      expect(controller.isRegisteredMentor, true);
      expect(controller.myProfile?.mentoringBio, contains('Experienced'));
    });

    test('toggleMentorStatus changes status successfully', () async {
      final success = await controller.toggleMentorStatus(
        MentorStatus.unavailable,
      );
      expect(success, true);
      expect(controller.myProfile?.status, MentorStatus.unavailable);
    });

    test('createSlot succeeds and triggers refresh', () async {
      const request = CreateSlotRequest(
        topic: 'Graph Algorithms',
        description: 'Deep dive into DFS/BFS',
        scheduleType: ScheduleType.oneTime,
        startDate: '2026-10-30',
        startTime: '14:00:00',
        endTime: '15:00:00',
        mode: SlotMode.online,
        meetingLink: 'https://meet.uniconnect.local/graphs',
        capacity: 4,
      );
      final success = await controller.createSlot(request);
      expect(success, true);
    });

    test('joinSlot and leaveSlot execute cleanly', () async {
      const joinReq = EnrollSlotRequest(
        joinMessage: 'Glad to join!',
        learningGoal: 'Master Graphs',
      );
      final joined = await controller.joinSlot(101, joinReq);
      expect(joined, true);

      final left = await controller.leaveSlot(101);
      expect(left, true);
    });

    test('loadAttendees caches attendee roster by slot ID', () async {
      repository.fakeAttendees = [
        const MentorshipEnrollment(
          enrollmentId: 1,
          slotId: 101,
          slotTopic: 'Algorithms Review',
          menteeId: 44,
          menteeName: 'Test Mentee',
          status: EnrollmentStatus.active,
        ),
      ];
      final attendees = await controller.loadAttendees(101);
      expect(attendees?.length, 1);
      expect(controller.slotAttendees[101]?.length, 1);
      expect(controller.slotAttendees[101]?.first.menteeName, 'Test Mentee');
    });

    test('profile service failure remains visible instead of appearing unregistered', () async {
      repository.throwError = true;
      await controller.loadMyProfile();
      expect(controller.error, 'Mentor profile service unavailable');
    });

    test(
      'reopen refreshes the sessions and releases mutation loading state',
      () async {
        expect(await controller.reopenSlot(101), isTrue);
        expect(controller.loading, isFalse);
        expect(controller.myMentoringSlots, isNotEmpty);
      },
    );

    test('selectTab switches tab and clears error', () {
      controller.error = 'Old error';
      controller.clearError();
      expect(controller.error, isNull);

      controller.selectTab(MentorshipTab.slots);
      expect(controller.activeTab, MentorshipTab.slots);
    });

    test('invalidate resets generation counters and error', () {
      controller.error = 'Temporary issue';
      controller.invalidate();
      expect(controller.error, isNull);
      expect(controller.loading, false);
    });
  });
}
