import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile.dart';
import 'package:uniconnect/features/mentorship/model/mentor_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_filter_params.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';

enum MentorshipTab {
  mentors,
  slots,
  mySessions,
}

class MentorshipController extends ChangeNotifier {
  MentorshipController(this.repository);

  final MentorshipRepository repository;
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
    } on AuthFailure catch (e) {
      if (_disposed || generation != _profileGeneration) return;
      // If 404, user is simply not registered as a mentor yet
      if (e.message.contains('not found') || e.message.contains('profile')) {
        myProfile = null;
        isRegisteredMentor = false;
      } else {
        error = e.message;
      }
    } finally {
      if (!_disposed && generation == _profileGeneration) {
        myProfileLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> registerMentor(MentorRegistrationRequest request) async {
    if (_disposed) return false;
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
    } finally {
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

  void selectTab(MentorshipTab tab) {
    if (_disposed || _activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
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
