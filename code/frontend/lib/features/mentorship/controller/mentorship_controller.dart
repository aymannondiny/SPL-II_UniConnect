import 'dart:async';

import 'package:uniconnect/features/mentorship/model/mentor_profile_missing.dart';

import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/create_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile.dart';
import 'package:uniconnect/features/mentorship/model/mentor_registration_request.dart';
import 'package:uniconnect/features/mentorship/model/mentor_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_filter_params.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';
import 'package:uniconnect/features/mentorship/model/update_slot_request.dart';

enum MentorshipTab { mentors, slots, mySessions }

class MentorshipController extends ChangeNotifier {
  MentorshipController(this.repository);

  final MentorshipRepository repository;
  int participationRevision = 0;
  bool _disposed = false;

  MentorshipTab _activeTab = MentorshipTab.mentors;
  MentorshipTab get activeTab => _activeTab;

  bool loading = false;
  String? error;

  List<MentorSummary> mentors = [];
  int totalMentors = 0;
  MentorFilterParams mentorFilters = const MentorFilterParams();
  bool mentorsLoading = false;
  bool mentorsLoadingMore = false;
  int _mentorsGeneration = 0;

  Future<void> loadMentors({bool more = false}) async {
    if (_disposed || (more && (mentorsLoadingMore || mentorsLoading))) return;
    if (more && (mentorFilters.page + 1) * mentorFilters.size >= totalMentors) {
      return;
    }
    final targetPage = more ? mentorFilters.page + 1 : 0;
    final generation = ++_mentorsGeneration;
    if (more) {
      mentorsLoadingMore = true;
    } else {
      mentorsLoading = true;
    }
    error = null;
    notifyListeners();

    try {
      final updatedParams = mentorFilters.copyWith(page: targetPage);
      final page = await repository.browseMentors(updatedParams);
      if (_disposed || generation != _mentorsGeneration) return;
      mentorFilters = updatedParams;
      totalMentors = page.totalElements;
      if (more) {
        mentors = [...mentors, ...page.items];
      } else {
        mentors = page.items;
      }
    } on AuthFailure catch (e) {
      if (_disposed || generation != _mentorsGeneration) return;
      error = e.message;
    } finally {
      if (!_disposed && generation == _mentorsGeneration) {
        mentorsLoading = false;
        mentorsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void updateMentorFilters(MentorFilterParams params) {
    if (_disposed) return;
    mentorFilters = params.copyWith(page: 0);
    unawaited(loadMentors());
  }

  List<MentorshipSlotSummary> slots = [];
  int totalSlots = 0;
  SlotFilterParams slotFilters = const SlotFilterParams();
  bool slotsLoading = false;
  bool slotsLoadingMore = false;
  int _slotsGeneration = 0;

  Future<void> loadSlots({bool more = false}) async {
    if (_disposed || (more && (slotsLoadingMore || slotsLoading))) return;
    if (more && (slotFilters.page + 1) * slotFilters.size >= totalSlots) {
      return;
    }
    final targetPage = more ? slotFilters.page + 1 : 0;
    final generation = ++_slotsGeneration;
    if (more) {
      slotsLoadingMore = true;
    } else {
      slotsLoading = true;
    }
    error = null;
    notifyListeners();

    try {
      final updatedParams = slotFilters.copyWith(page: targetPage);
      final page = await repository.browseSlots(updatedParams);
      if (_disposed || generation != _slotsGeneration) return;
      slotFilters = updatedParams;
      totalSlots = page.totalElements;
      if (more) {
        slots = [...slots, ...page.items];
      } else {
        slots = page.items;
      }
    } on AuthFailure catch (e) {
      if (_disposed || generation != _slotsGeneration) return;
      error = e.message;
    } finally {
      if (!_disposed && generation == _slotsGeneration) {
        slotsLoading = false;
        slotsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void updateSlotFilters(SlotFilterParams params) {
    if (_disposed) return;
    slotFilters = params.copyWith(page: 0);
    unawaited(loadSlots());
  }

  List<MentorshipSlotSummary> myMentoringSlots = [];
  List<MentorshipSlotSummary> myEnrolledSlots = [];
  bool sessionsLoading = false;
  int _sessionsGeneration = 0;

  Future<void> loadMySessions() async {
    if (_disposed || sessionsLoading) return;
    final generation = ++_sessionsGeneration;
    sessionsLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getMyMentoringSlots(),
        repository.getMyEnrolledSlots(),
      ]);
      if (_disposed || generation != _sessionsGeneration) return;
      myMentoringSlots = results[0];
      myEnrolledSlots = results[1];
    } on AuthFailure catch (e) {
      if (_disposed || generation != _sessionsGeneration) return;
      error = e.message;
    } finally {
      if (!_disposed && generation == _sessionsGeneration) {
        sessionsLoading = false;
        notifyListeners();
      }
    }
  }

  MentorProfile? myProfile;
  bool myProfileLoading = false;
  bool isRegisteredMentor = false;
  bool _registrationInProgress = false;
  int _profileGeneration = 0;

  Future<void> loadMyProfile() async {
    if (_disposed || myProfileLoading) return;
    final generation = ++_profileGeneration;
    myProfileLoading = true;
    error = null;
    notifyListeners();

    try {
      final profile = await repository.getMyMentorProfile();
      if (_disposed || generation != _profileGeneration) return;
      myProfile = profile;
      isRegisteredMentor = true;
    } on MentorProfileMissing {
      if (_disposed || generation != _profileGeneration) return;
      myProfile = null;
      isRegisteredMentor = false;
    } on AuthFailure catch (failure) {
      if (_disposed || generation != _profileGeneration) return;
      error = failure.message;
    } finally {
      if (!_disposed && generation == _profileGeneration) {
        myProfileLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> registerMentor(MentorRegistrationRequest request) async {
    if (_disposed || _registrationInProgress) return false;
    _registrationInProgress = true;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final created = await repository.registerAsMentor(request);
      if (_disposed) return false;
      myProfile = created;
      isRegisteredMentor = true;
      unawaited(loadMentors());
      return true;
    } on AuthFailure catch (e) {
      if (_disposed) return false;
      error = e.message;
      return false;
    } on Object {
      if (_disposed) return false;
      error =
          'Unable to confirm mentor registration. Please refresh and retry.';
      return false;
    } finally {
      _registrationInProgress = false;
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> toggleMentorStatus(MentorStatus status) async {
    if (_disposed) return false;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final updated = await repository.updateMentorStatus(status);
      if (_disposed) return false;
      myProfile = updated;
      unawaited(loadMentors());
      return true;
    } on AuthFailure catch (e) {
      if (_disposed) return false;
      error = e.message;
      return false;
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createSlot(CreateSlotRequest request) =>
      _mutateSlot(() => repository.createSlot(request));

  Future<bool> updateSlot(int slotId, UpdateSlotRequest request) =>
      _mutateSlot(() => repository.updateSlot(slotId, request));

  Future<bool> closeSlot(int slotId) =>
      _mutateSlot(() => repository.closeSlot(slotId));

  Future<bool> reopenSlot(int slotId) =>
      _mutateSlot(() => repository.reopenSlot(slotId));

  Future<bool> cancelSlot(int slotId) =>
      _mutateSlot(() => repository.cancelSlot(slotId));

  Future<bool> joinSlot(int slotId, EnrollSlotRequest request) =>
      _mutateSlot(() => repository.joinSlot(slotId, request));

  Future<bool> leaveSlot(int slotId) =>
      _mutateSlot(() => repository.leaveSlot(slotId));

  Future<bool> _mutateSlot(Future<Object> Function() action) async {
    if (_disposed || loading) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await action();
      if (_disposed) return false;
      participationRevision++;
      if (result is MentorshipSlot) {
        final saved = MentorshipSlotSummary.fromJson(result.toJson());
        myMentoringSlots =
            [
              ...myMentoringSlots.where((slot) => slot.slotId != saved.slotId),
              saved,
            ]..sort(
              (a, b) => '${a.startDate} ${a.startTime}'.compareTo(
                '${b.startDate} ${b.startTime}',
              ),
            );
      }
      // The write is already committed. Slow directory reads must not keep the
      // publishing dialog open or turn a successful save into a failed post.
      _sessionsGeneration++;
      sessionsLoading = false;
      unawaited(_refreshAfterSlotMutation());
      return true;
    } on AuthFailure catch (failure) {
      if (!_disposed) error = failure.message;
      return false;
    } on Object {
      if (!_disposed) {
        error = 'Unable to confirm the session change. Check My Sessions before trying again.';
      }
      return false;
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _refreshAfterSlotMutation() async {
    try {
      await Future.wait([loadSlots(), loadMySessions()]);
      if (_disposed || error == null) return;
    } on Object {
      if (_disposed) return;
    }
    error = 'Your change was saved, but the session lists could not refresh. Refresh My Sessions to load the latest information.';
    notifyListeners();
  }

  Map<int, List<MentorshipEnrollment>> slotAttendees = {};
  bool attendeesLoading = false;

  Future<List<MentorshipEnrollment>?> loadAttendees(int slotId) async {
    if (_disposed) return null;
    attendeesLoading = true;
    error = null;
    notifyListeners();

    try {
      final list = await repository.getSlotAttendees(slotId);
      if (_disposed) return null;
      slotAttendees = {...slotAttendees, slotId: list};
      return list;
    } on AuthFailure catch (e) {
      if (_disposed) return null;
      error = e.message;
      return null;
    } finally {
      if (!_disposed) {
        attendeesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadAll() async {
    if (_disposed) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadMentors(),
        loadSlots(),
        loadMySessions(),
        loadMyProfile(),
      ]);
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshActiveTab() async {
    switch (_activeTab) {
      case MentorshipTab.mentors:
        await loadMentors();
      case MentorshipTab.slots:
        await loadSlots();
      case MentorshipTab.mySessions:
        await Future.wait([loadMySessions(), loadMyProfile()]);
    }
  }

  void invalidate() {
    _mentorsGeneration++;
    _slotsGeneration++;
    _sessionsGeneration++;
    _profileGeneration++;
    mentorsLoading = false;
    mentorsLoadingMore = false;
    slotsLoading = false;
    slotsLoadingMore = false;
    sessionsLoading = false;
    myProfileLoading = false;
    attendeesLoading = false;
    loading = false;
    error = null;
    notifyListeners();
  }

  void selectTab(MentorshipTab tab) {
    if (_disposed || _activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
    refreshActiveTab();
  }

  void clearError() {
    if (error != null) {
      error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
