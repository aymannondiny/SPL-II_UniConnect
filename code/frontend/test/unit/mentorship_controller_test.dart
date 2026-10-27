import 'dart:async';

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
  Object? registrationFailure;
  Completer<MentorProfile>? pendingRegistration;
  int registrationCalls = 0;
  Object? createFailure;
  Completer<MentorshipPageResult<MentorshipSlotSummary>>? pendingSlotRefresh;
  Completer<List<MentorshipSlotSummary>>? pendingSessionRefresh;
  int mentorReads = 0,
      slotReads = 0,
      profileReads = 0,
      hostedReads = 0,
      enrolledReads = 0;
  final mentorTopics = <String?>[];
  Future<MentorshipPageResult<MentorSummary>> Function(MentorFilterParams)?
  mentorSearch;

  @override
  Future<MentorshipPageResult<MentorSummary>> browseMentors(
    MentorFilterParams params,
  ) async {
    mentorReads++;
    mentorTopics.add(params.topic);
    if (mentorSearch != null) return mentorSearch!(params);
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
    profileReads++;
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
    registrationCalls++;
    if (registrationFailure != null) throw registrationFailure!;
    if (pendingRegistration != null) return pendingRegistration!.future;
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
    slotReads++;
    if (pendingSlotRefresh != null) return pendingSlotRefresh!.future;
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
    if (createFailure != null) throw createFailure!;
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
    hostedReads++;
    if (pendingSessionRefresh != null) return pendingSessionRefresh!.future;
    if (throwError) throw const AuthFailure('Error');
    return fakeSlots;
  }

  @override
  Future<List<MentorshipSlotSummary>> getMyEnrolledSlots() async {
    enrolledReads++;
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
    test(
      'initial load and cached tab visits fetch only the required data',
      () async {
        await controller.loadInitial();
        expect(repository.mentorReads, 1);
        expect(repository.profileReads, 1);
        expect(
          repository.slotReads +
              repository.hostedReads +
              repository.enrolledReads,
          0,
        );
        await controller.loadInitial();
        expect(repository.mentorReads, 1);
        expect(
          repository.profileReads,
          1,
        ); // An absent mentor profile is cached too.
        controller.selectTab(MentorshipTab.slots);
        await controller.ensureSlots();
        expect(repository.slotReads, 1);
        controller.selectTab(MentorshipTab.mentors);
        await controller.ensureMentors();
        expect(repository.mentorReads, 1);
        controller.selectTab(MentorshipTab.mySessions);
        await controller.ensureMySessions();
        expect(repository.hostedReads, 1);
        expect(repository.enrolledReads, 1);
        await controller.loadInitial();
        expect(repository.hostedReads, 1);
        expect(repository.profileReads, 1);
      },
    );

    test(
      'empty results are cached and explicit refresh still reloads',
      () async {
        repository.fakeMentors = [];
        await controller.loadInitial();
        await controller.ensureMentors();
        expect(repository.mentorReads, 1);
        await controller.refreshActiveTab();
        expect(repository.mentorReads, 2);
        expect(repository.profileReads, 2);
      },
    );

    test(
      'overlapping directory loads share one request and await its result',
      () async {
        final pending = Completer<MentorshipPageResult<MentorSummary>>();
        repository.mentorSearch = (_) => pending.future;
        final first = controller.loadMentors();
        final duplicate = controller.loadMentors();
        expect(repository.mentorReads, 1);
        pending.complete(
          MentorshipPageResult(
            items: repository.fakeMentors,
            page: 0,
            size: 10,
            totalElements: 1,
          ),
        );
        await Future.wait([first, duplicate]);
        expect(controller.mentors.single.fullName, 'Tahmid Khan');
        expect(controller.mentorsLoading, isFalse);
      },
    );

    testWidgets('typing is debounced and searches only the final topic', (
      tester,
    ) async {
      controller.updateMentorFilters(
        const MentorFilterParams(topic: 'm'),
        debounce: true,
      );
      controller.updateMentorFilters(
        const MentorFilterParams(topic: 'ma'),
        debounce: true,
      );
      controller.updateMentorFilters(
        const MentorFilterParams(topic: 'math'),
        debounce: true,
      );
      await tester.pump(const Duration(milliseconds: 299));
      expect(repository.mentorReads, 0);
      await tester.pump(const Duration(milliseconds: 2));
      expect(repository.mentorTopics, ['math']);
      expect(controller.mentorsLoading, isFalse);
    });

    test(
      'outdated search responses never replace the latest filter results',
      () async {
        final older = Completer<MentorshipPageResult<MentorSummary>>();
        repository.mentorSearch = (params) async => params.topic == 'old'
            ? older.future
            : MentorshipPageResult(
                items: [],
                page: 0,
                size: 10,
                totalElements: 0,
              );
        controller.updateMentorFilters(const MentorFilterParams(topic: 'old'));
        controller.updateMentorFilters(const MentorFilterParams(topic: 'new'));
        await controller.loadMentors();
        older.complete(
          MentorshipPageResult(
            items: repository.fakeMentors,
            page: 0,
            size: 10,
            totalElements: 1,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.mentorFilters.topic, 'new');
        expect(controller.mentors, isEmpty);
        expect(controller.totalMentors, 0);
      },
    );

    test('expired results are reloaded on the next visit', () async {
      controller.dispose();
      controller = MentorshipController(
        repository,
        cacheDuration: const Duration(milliseconds: 1),
      );
      await controller.loadInitial();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await controller.loadInitial();
      expect(repository.mentorReads, 2);
      expect(repository.profileReads, 2);
    });

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

    test(
      'joined sessions appear without waiting for a slow hosted list',
      () async {
        repository.pendingSessionRefresh = Completer();
        final pending = controller.loadMySessions();
        await Future<void>.delayed(Duration.zero);
        expect(controller.myEnrolledSlots, isNotEmpty);
        expect(controller.enrolledSessionsLoading, isFalse);
        expect(controller.hostedSessionsLoading, isTrue);
        repository.pendingSessionRefresh!.complete([]);
        await pending;
        expect(controller.sessionsLoading, isFalse);
      },
    );

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

    test(
      'registration releases loading after an unexpected response failure',
      () async {
        repository.registrationFailure = StateError('Invalid server response');
        final success = await controller.registerMentor(
          const MentorRegistrationRequest(
            mentoringBio: 'I love math and physics.',
            expertise: [MentorExpertiseInput(topic: 'math')],
          ),
        );
        expect(success, isFalse);
        expect(controller.loading, isFalse);
        expect(controller.error, contains('Unable to confirm'));
      },
    );

    test('a pending registration cannot be submitted twice', () async {
      repository.pendingRegistration = Completer<MentorProfile>();
      const request = MentorRegistrationRequest(
        mentoringBio: 'I love math and physics.',
        expertise: [MentorExpertiseInput(topic: 'math')],
      );
      final first = controller.registerMentor(request);
      expect(await controller.registerMentor(request), isFalse);
      expect(repository.registrationCalls, 1);
      repository.pendingRegistration!.complete(
        const MentorProfile(
          mentorProfileId: 7,
          userId: 20,
          fullName: 'Test Mentor',
          role: 'STUDENT',
          mentoringBio: 'I love math and physics.',
          status: MentorStatus.available,
          expertise: [],
        ),
      );
      expect(await first, isTrue);
      expect(controller.loading, isFalse);
    });

    test('toggleMentorStatus changes status successfully', () async {
      final success = await controller.toggleMentorStatus(
        MentorStatus.unavailable,
      );
      expect(success, true);
      expect(controller.myProfile?.status, MentorStatus.unavailable);
    });

    test(
      'createSlot succeeds without waiting for slow list refreshes',
      () async {
        controller.selectTab(MentorshipTab.mySessions);
        await controller.ensureMySessions();
        controller.myMentoringSlots = [];
        repository.pendingSessionRefresh = Completer();
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
        expect(controller.loading, isFalse);
        expect(controller.myMentoringSlots.single.topic, request.topic);
        expect(controller.sessionsLoading, isTrue);
        expect(repository.slotReads, 0);
        repository.pendingSessionRefresh!.completeError(
          const AuthFailure('Refresh timed out'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.error, contains('Your change was saved'));
        expect(controller.myMentoringSlots.single.topic, request.topic);
      },
    );

    test(
      'unexpected publish failure releases loading for another attempt',
      () async {
        repository.createFailure = const FormatException('Invalid response');
        const request = CreateSlotRequest(
          topic: 'Graphs',
          description: 'Graph practice',
          scheduleType: ScheduleType.oneTime,
          startDate: '2026-11-01',
          startTime: '14:00:00',
          endTime: '15:00:00',
          mode: SlotMode.online,
          meetingLink: 'https://meet.example.test/graphs',
          capacity: 5,
        );
        expect(await controller.createSlot(request), isFalse);
        expect(controller.loading, isFalse);
        expect(controller.error, contains('Check My Sessions'));
        repository.createFailure = null;
        expect(await controller.createSlot(request), isTrue);
      },
    );

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
