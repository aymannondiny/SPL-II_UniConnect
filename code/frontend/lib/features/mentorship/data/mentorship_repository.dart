import 'package:flutter/foundation.dart';
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

@immutable
class MentorshipPage<T> {
  const MentorshipPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
  });

  final List<T> items;
  final int page;
  final int size;
  final int totalElements;

  bool get hasMore => (page + 1) * size < totalElements;

  factory MentorshipPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    return MentorshipPage<T>(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => parseItem(e as Map<String, dynamic>))
              .toList() ??
          const [],
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 10,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}

abstract interface class MentorshipRepository {
  Future<MentorshipPage<MentorSummary>> browseMentors(
    MentorFilterParams params,
  );
  Future<MentorProfile> getMentorProfile(int mentorProfileId);
  Future<MentorProfile> getMyMentorProfile();
  Future<MentorProfile> registerAsMentor(MentorRegistrationRequest request);
  Future<MentorProfile> updateMentorStatus(MentorStatus status);

  Future<MentorshipPage<MentorshipSlotSummary>> browseSlots(
    SlotFilterParams params,
  );
  Future<MentorshipSlot> getSlotDetails(int slotId);
  Future<MentorshipSlot> createSlot(CreateSlotRequest request);
  Future<MentorshipSlot> updateSlot(int slotId, UpdateSlotRequest request);
  Future<MentorshipEnrollment> joinSlot(int slotId, EnrollSlotRequest request);
  Future<MentorshipEnrollment> leaveSlot(int slotId);
  Future<MentorshipSlot> closeSlot(int slotId);
  Future<MentorshipSlot> cancelSlot(int slotId);

  Future<List<MentorshipSlotSummary>> getMyMentoringSlots();
  Future<List<MentorshipSlotSummary>> getMyEnrolledSlots();
  Future<List<MentorshipEnrollment>> getSlotAttendees(int slotId);
}
