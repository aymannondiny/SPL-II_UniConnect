import 'package:flutter_test/flutter_test.dart';
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

void main() {
  group('Mentorship Enums Tests', () {
    test('MentorStatus serialization', () {
      expect(MentorStatusX.fromApi('AVAILABLE'), MentorStatus.available);
      expect(MentorStatusX.fromApi('UNAVAILABLE'), MentorStatus.unavailable);
      expect(MentorStatus.available.toApi(), 'AVAILABLE');
      expect(MentorStatus.available.label, 'Available');
    });

    test('SlotStatus serialization', () {
      expect(SlotStatusX.fromApi('OPEN'), SlotStatus.open);
      expect(SlotStatusX.fromApi('FULL'), SlotStatus.full);
      expect(SlotStatusX.fromApi('CLOSED'), SlotStatus.closed);
      expect(SlotStatusX.fromApi('CANCELLED'), SlotStatus.cancelled);
      expect(SlotStatus.open.toApi(), 'OPEN');
      expect(SlotStatus.open.label, 'Open');
    });

    test('ScheduleType serialization', () {
      expect(ScheduleTypeX.fromApi('ONE_TIME'), ScheduleType.oneTime);
      expect(ScheduleTypeX.fromApi('WEEKLY'), ScheduleType.weekly);
      expect(ScheduleTypeX.fromApi('BIWEEKLY'), ScheduleType.biweekly);
      expect(ScheduleType.weekly.toApi(), 'WEEKLY');
      expect(ScheduleType.weekly.label, 'Weekly');
    });

    test('SlotMode serialization', () {
      expect(SlotModeX.fromApi('ONLINE'), SlotMode.online);
      expect(SlotModeX.fromApi('IN_PERSON'), SlotMode.inPerson);
      expect(SlotMode.online.toApi(), 'ONLINE');
      expect(SlotMode.online.label, 'Online');
    });

    test('EnrollmentStatus serialization', () {
      expect(EnrollmentStatusX.fromApi('ACTIVE'), EnrollmentStatus.active);
      expect(EnrollmentStatusX.fromApi('LEFT'), EnrollmentStatus.left);
      expect(
        EnrollmentStatusX.fromApi('CANCELLED'),
        EnrollmentStatus.cancelled,
      );
      expect(EnrollmentStatus.active.toApi(), 'ACTIVE');
      expect(EnrollmentStatus.active.label, 'Enrolled');
    });
  });

  group('Mentorship Models JSON Tests', () {
    test('MentorSummary deserializes accurately', () {
      final json = {
        'mentorProfileId': 10,
        'userId': 20,
        'fullName': 'Amina Rahman',
        'role': 'STUDENT',
        'departmentName': 'Computer Science',
        'yearOfStudy': 3,
        'graduationYear': null,
        'profilePhotoUrl': 'https://example.com/photo.jpg',
        'status': 'AVAILABLE',
        'expertiseTopics': ['Algorithms', 'Java'],
      };
      final summary = MentorSummary.fromJson(json);
      expect(summary.mentorProfileId, 10);
      expect(summary.userId, 20);
      expect(summary.fullName, 'Amina Rahman');
      expect(summary.departmentName, 'Computer Science');
      expect(summary.yearOfStudy, 3);
      expect(summary.status, MentorStatus.available);
      expect(summary.expertiseTopics, ['Algorithms', 'Java']);
      expect(summary.toJson()['fullName'], 'Amina Rahman');
    });

    test('MentorProfile deserializes and converts to JSON', () {
      final json = {
        'mentorProfileId': 10,
        'userId': 20,
        'fullName': 'Amina Rahman',
        'role': 'STUDENT',
        'mentoringBio': 'Passionate about algorithms and career mentoring.',
        'status': 'AVAILABLE',
        'expertise': [
          {'topic': 'Algorithms', 'description': 'Graph theory'},
        ],
        'registeredAt': '2026-10-15T10:00:00',
        'updatedAt': '2026-10-15T12:00:00',
      };
      final profile = MentorProfile.fromJson(json);
      expect(profile.mentorProfileId, 10);
      expect(profile.mentoringBio, contains('Passionate'));
      expect(profile.expertise.length, 1);
      expect(profile.expertise.first.topic, 'Algorithms');
      expect(profile.expertise.first.description, 'Graph theory');
      expect(profile.registeredAt, isNotNull);
    });

    test('MentorshipSlot deserializes and computes status helpers', () {
      final json = {
        'slotId': 101,
        'mentorProfileId': 10,
        'mentorUserId': 20,
        'mentorName': 'Amina Rahman',
        'topic': 'Graph Theory Deep Dive',
        'description': 'Master shortest paths and minimum spanning trees.',
        'scheduleType': 'WEEKLY',
        'startDate': '2026-10-25',
        'startTime': '14:00:00',
        'endTime': '15:30:00',
        'recurrenceEndDate': '2026-11-25',
        'mode': 'ONLINE',
        'meetingLink': 'https://meet.uniconnect.local/graphs',
        'capacity': 5,
        'currentMenteeCount': 2,
        'status': 'OPEN',
        'occurrences': ['2026-10-25', '2026-11-01'],
      };
      final slot = MentorshipSlot.fromJson(json);
      expect(slot.slotId, 101);
      expect(slot.topic, 'Graph Theory Deep Dive');
      expect(slot.scheduleType, ScheduleType.weekly);
      expect(slot.mode, SlotMode.online);
      expect(slot.capacity, 5);
      expect(slot.currentMenteeCount, 2);
      expect(slot.availableSeats, 3);
      expect(slot.isFull, false);
      expect(slot.isOpen, true);
      expect(slot.occurrences.length, 2);
    });

    test('MentorshipSlotSummary deserializes accurately', () {
      final json = {
        'slotId': 102,
        'mentorProfileId': 10,
        'mentorUserId': 20,
        'mentorName': 'Amina Rahman',
        'topic': 'System Design Intro',
        'description': 'Designing scalable microservices.',
        'scheduleType': 'ONE_TIME',
        'startDate': '2026-10-28',
        'startTime': '16:00:00',
        'endTime': '17:00:00',
        'mode': 'IN_PERSON',
        'location': 'CS Seminar Hall B',
        'capacity': 10,
        'currentMenteeCount': 10,
        'status': 'FULL',
      };
      final summary = MentorshipSlotSummary.fromJson(json);
      expect(summary.slotId, 102);
      expect(summary.status, SlotStatus.full);
      expect(summary.isFull, true);
      expect(summary.isOpen, false);
      expect(summary.availableSeats, 0);
    });

    test('MentorshipEnrollment deserializes correctly', () {
      final json = {
        'enrollmentId': 50,
        'slotId': 101,
        'slotTopic': 'Graph Theory Deep Dive',
        'menteeId': 35,
        'menteeName': 'Farhan Khan',
        'joinMessage': 'Excited for this workshop!',
        'learningGoal': 'Understand Dijkstra implementation.',
        'status': 'ACTIVE',
        'joinedAt': '2026-10-20T08:00:00',
      };
      final enrollment = MentorshipEnrollment.fromJson(json);
      expect(enrollment.enrollmentId, 50);
      expect(enrollment.menteeName, 'Farhan Khan');
      expect(enrollment.isActive, true);
      expect(enrollment.learningGoal, contains('Dijkstra'));
    });

    test('MentorshipPage parses items and pagination info', () {
      final json = {
        'items': [
          {
            'mentorProfileId': 1,
            'userId': 2,
            'fullName': 'Mentor 1',
            'role': 'STUDENT',
            'status': 'AVAILABLE',
            'expertiseTopics': ['AI'],
          },
        ],
        'page': 0,
        'size': 10,
        'totalElements': 25,
      };
      final page = MentorshipPage<MentorSummary>.fromJson(
        json,
        MentorSummary.fromJson,
      );
      expect(page.items.length, 1);
      expect(page.page, 0);
      expect(page.totalElements, 25);
      expect(page.hasMore, true);
    });
  });

  group('Mentorship Request Validation Tests', () {
    test('MentorRegistrationRequest validates bio and expertise', () {
      const invalidShortBio = MentorRegistrationRequest(
        mentoringBio: 'Too short',
        expertise: [MentorExpertiseInput(topic: 'Dart')],
      );
      expect(invalidShortBio.validate(), contains('at least 10 characters'));

      const invalidNoExpertise = MentorRegistrationRequest(
        mentoringBio: 'Experienced senior student ready to mentor peers.',
        expertise: [],
      );
      expect(invalidNoExpertise.validate(), contains('at least one expertise'));

      const validRequest = MentorRegistrationRequest(
        mentoringBio: 'Experienced senior student ready to mentor peers.',
        expertise: [
          MentorExpertiseInput(topic: 'Flutter', description: 'UI/UX'),
        ],
      );
      expect(validRequest.validate(), isNull);
    });

    test('CreateSlotRequest validates fields and mode requirements', () {
      const invalidOnlineWithoutLink = CreateSlotRequest(
        topic: 'Flutter State Management',
        description: 'Comprehensive walkthrough of Riverpod and Provider.',
        scheduleType: ScheduleType.weekly,
        startDate: '2026-10-30',
        startTime: '10:00:00',
        endTime: '11:30:00',
        mode: SlotMode.online,
        meetingLink: null,
        capacity: 5,
      );
      expect(
        invalidOnlineWithoutLink.validate(),
        contains('Meeting link is required'),
      );

      const validRequest = CreateSlotRequest(
        topic: 'Flutter State Management',
        description: 'Comprehensive walkthrough of Riverpod and Provider.',
        scheduleType: ScheduleType.weekly,
        startDate: '2026-10-30',
        startTime: '10:00:00',
        endTime: '11:30:00',
        mode: SlotMode.online,
        meetingLink: 'https://meet.uniconnect.local/flutter',
        capacity: 5,
      );
      expect(validRequest.validate(), isNull);
    });

    test('MentorFilterParams generates query parameters correctly', () {
      const params = MentorFilterParams(
        topic: 'React',
        departmentId: 4,
        yearOfStudy: 3,
        page: 1,
        size: 15,
      );
      final query = params.toQueryParameters();
      expect(query['topic'], 'React');
      expect(query['departmentId'], '4');
      expect(query['yearOfStudy'], '3');
      expect(query['page'], '1');
      expect(query['size'], '15');
    });

    test('SlotFilterParams generates query parameters correctly', () {
      const params = SlotFilterParams(
        status: SlotStatus.open,
        mode: SlotMode.online,
        topic: 'Spring',
        page: 0,
        size: 10,
      );
      final query = params.toQueryParameters();
      expect(query['status'], 'OPEN');
      expect(query['mode'], 'ONLINE');
      expect(query['topic'], 'Spring');
    });
  });
}
