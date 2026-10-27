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
  MentorshipController(
    this.repository, {
    this.cacheDuration = const Duration(seconds: 30),
    this.searchDebounce = const Duration(milliseconds: 300),
  });

  final MentorshipRepository repository;
  final Duration cacheDuration;
  final Duration searchDebounce;

  DateTime? _mentorsLoadedAt,
      _slotsLoadedAt,
      _sessionsLoadedAt,
      _profileLoadedAt;

  Future<void>? _mentorsRequest,
      _slotsRequest,
      _sessionsRequest,
      _profileRequest;

  Timer? _mentorSearchTimer, _slotSearchTimer;
  int _slotMutationGeneration = 0;
  int participationRevision = 0;
  bool _disposed = false;
  bool _stale(DateTime? loadedAt) =>
      loadedAt == null || DateTime.now().difference(loadedAt) >= cacheDuration;

  Future<void> ensureMentors() =>
      _stale(_mentorsLoadedAt) ? loadMentors() : Future.value();
  Future<void> ensureSlots() =>
      _stale(_slotsLoadedAt) ? loadSlots() : Future.value();
  Future<void> ensureMySessions() =>
      _stale(_sessionsLoadedAt) ? loadMySessions() : Future.value();
  Future<void> ensureMyProfile() =>
      _stale(_profileLoadedAt) ? loadMyProfile() : Future.value();

  /// First paint only needs the selected directory and the header's mentor state.
  Future<void> loadInitial() => Future.wait<void>([
    switch (_activeTab) {
      MentorshipTab.mentors => ensureMentors(),
      MentorshipTab.slots => ensureSlots(),
      MentorshipTab.mySessions => ensureMySessions(),
    },
    ensureMyProfile(),
  ]);

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

  Future<void> loadMentors({bool more = false}) {
    if (_disposed) return Future.value();
    if (!more) {
      _mentorSearchTimer?.cancel();
      _mentorSearchTimer = null;
    }
    if (_mentorsRequest != null) return _mentorsRequest!;
    late final Future<void> request;
    request = _loadMentors(more: more).whenComplete(() {
      if (identical(_mentorsRequest, request)) _mentorsRequest = null;
    });
    return _mentorsRequest = request;
  }

  Future<void> _loadMentors({bool more = false}) async {
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
      _mentorsLoadedAt = DateTime.now();
      if (more) {
        mentors = [...mentors, ...page.items];
      } else {
        mentors = page.items;
      }
    } on AuthFailure catch (e) {
      if (_disposed || generation != _mentorsGeneration) return;
      error = e.message;
    } on Object {
      if (_disposed || generation != _mentorsGeneration) return;
      error = 'Unable to load mentors. Please refresh and try again.';
    } finally {
      if (!_disposed && generation == _mentorsGeneration) {
        mentorsLoading = false;
        mentorsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void updateMentorFilters(MentorFilterParams params, {bool debounce = false}) {
    if (_disposed) return;
    _mentorSearchTimer?.cancel();
    _mentorsGeneration++;
    _mentorsRequest = null;
    _mentorsLoadedAt = null;
    mentorsLoading = false;
    mentorsLoadingMore = false;
    mentorFilters = params.copyWith(page: 0);
    if (debounce) {
      mentorsLoading = true;
      notifyListeners();
      _mentorSearchTimer = Timer(searchDebounce, () {
        _mentorSearchTimer = null;
        unawaited(loadMentors());
      });
    } else {
      unawaited(loadMentors());
    }
  }

  void _invalidateMentorDirectory() {
    _mentorSearchTimer?.cancel();
    _mentorSearchTimer = null;
    _mentorsGeneration++;
    _mentorsRequest = null;
    _mentorsLoadedAt = null;
    mentorsLoading = mentorsLoadingMore = false;
  }

  List<MentorshipSlotSummary> slots = [];
  int totalSlots = 0;
  SlotFilterParams slotFilters = const SlotFilterParams();
  bool slotsLoading = false;
  bool slotsLoadingMore = false;
  int _slotsGeneration = 0;

  Future<void> loadSlots({bool more = false}) {
    if (_disposed) return Future.value();
    if (!more) {
      _slotSearchTimer?.cancel();
      _slotSearchTimer = null;
    }
    if (_slotsRequest != null) return _slotsRequest!;
    late final Future<void> request;
    request = _loadSlots(more: more).whenComplete(() {
      if (identical(_slotsRequest, request)) _slotsRequest = null;
    });
    return _slotsRequest = request;
  }

  Future<void> _loadSlots({bool more = false}) async {
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
      _slotsLoadedAt = DateTime.now();
      if (more) {
        slots = [...slots, ...page.items];
      } else {
        slots = page.items;
      }
    } on AuthFailure catch (e) {
      if (_disposed || generation != _slotsGeneration) return;
      error = e.message;
    } on Object {
      if (_disposed || generation != _slotsGeneration) return;
      error = 'Unable to load sessions. Please refresh and try again.';
    } finally {
      if (!_disposed && generation == _slotsGeneration) {
        slotsLoading = false;
        slotsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void updateSlotFilters(SlotFilterParams params, {bool debounce = false}) {
    if (_disposed) return;
    _slotSearchTimer?.cancel();
    _slotsGeneration++;
    _slotsRequest = null;
    _slotsLoadedAt = null;
    slotsLoading = false;
    slotsLoadingMore = false;
    slotFilters = params.copyWith(page: 0);
    if (debounce) {
      slotsLoading = true;
      notifyListeners();
      _slotSearchTimer = Timer(searchDebounce, () {
        _slotSearchTimer = null;
        unawaited(loadSlots());
      });
    } else {
      unawaited(loadSlots());
    }
  }

  List<MentorshipSlotSummary> myMentoringSlots = [];
  List<MentorshipSlotSummary> myEnrolledSlots = [];
  bool sessionsLoading = false;
  bool hostedSessionsLoading = false;
  bool enrolledSessionsLoading = false;
  int _sessionsGeneration = 0;

  Future<void> loadMySessions() {
    if (_disposed) return Future.value();
    if (_sessionsRequest != null) return _sessionsRequest!;
    late final Future<void> request;
    request = _loadMySessions().whenComplete(() {
      if (identical(_sessionsRequest, request)) _sessionsRequest = null;
    });
    return _sessionsRequest = request;
  }

  Future<void> _loadMySessions() async {
    if (_disposed || sessionsLoading) return;
    final generation = ++_sessionsGeneration;
    sessionsLoading = true;
    hostedSessionsLoading = enrolledSessionsLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        repository.getMyMentoringSlots().then((items) {
          if (_disposed || generation != _sessionsGeneration) return;
          myMentoringSlots = items;
          hostedSessionsLoading = false;
          notifyListeners();
        }),
        repository.getMyEnrolledSlots().then((items) {
          if (_disposed || generation != _sessionsGeneration) return;
          myEnrolledSlots = items;
          enrolledSessionsLoading = false;
          notifyListeners();
        }),
      ]);
      if (_disposed || generation != _sessionsGeneration) return;
      _sessionsLoadedAt = DateTime.now();
    } on AuthFailure catch (e) {
      if (_disposed || generation != _sessionsGeneration) return;
      error = e.message;
    } on Object {
      if (_disposed || generation != _sessionsGeneration) return;
      error = 'Unable to load your sessions. Please refresh and try again.';
    } finally {
      if (!_disposed && generation == _sessionsGeneration) {
        sessionsLoading = false;
        hostedSessionsLoading = enrolledSessionsLoading = false;
        notifyListeners();
      }
    }
  }

  MentorProfile? myProfile;
  bool myProfileLoading = false;
  bool isRegisteredMentor = false;
  bool _registrationInProgress = false;
  int _profileGeneration = 0;

  Future<void> loadMyProfile() {
    if (_disposed) return Future.value();
    if (_profileRequest != null) return _profileRequest!;
    late final Future<void> request;
    request = _loadMyProfile().whenComplete(() {
      if (identical(_profileRequest, request)) _profileRequest = null;
    });
    return _profileRequest = request;
  }

  Future<void> _loadMyProfile() async {
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
      _profileLoadedAt = DateTime.now();
    } on MentorProfileMissing {
      if (_disposed || generation != _profileGeneration) return;
      myProfile = null;
      isRegisteredMentor = false;
      _profileLoadedAt = DateTime.now();
    } on AuthFailure catch (failure) {
      if (_disposed || generation != _profileGeneration) return;
      error = failure.message;
    } on Object {
      if (_disposed || generation != _profileGeneration) return;
      error =
          'Unable to load your mentor profile. Please refresh and try again.';
    } finally {
      if (!_disposed && generation == _profileGeneration) {
        myProfileLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> registerMentor(MentorRegistrationRequest request) async {
    if (_disposed || loading || _registrationInProgress) return false;
    _registrationInProgress = true;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final created = await repository.registerAsMentor(request);
      if (_disposed) return false;
      myProfile = created;
      isRegisteredMentor = true;
      _profileGeneration++;
      _profileRequest = null;
      myProfileLoading = false;
      _profileLoadedAt = DateTime.now();
      _invalidateMentorDirectory();
      if (_activeTab == MentorshipTab.mentors) unawaited(loadMentors());
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
    if (_disposed || loading) return false;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final updated = await repository.updateMentorStatus(status);
      if (_disposed) return false;
      myProfile = updated;
      _profileGeneration++;
      _profileRequest = null;
      myProfileLoading = false;
      _profileLoadedAt = DateTime.now();
      _invalidateMentorDirectory();
      if (_activeTab == MentorshipTab.mentors) unawaited(loadMentors());
      return true;
    } on AuthFailure catch (e) {
      if (_disposed) return false;
      error = e.message;
      return false;
    } on Object {
      if (_disposed) return false;
      error =
          'Unable to update mentor availability. Please refresh and try again.';
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
    final mutation = ++_slotMutationGeneration;
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
      _sessionsRequest = null;
      _sessionsLoadedAt = null;
      sessionsLoading = false;
      hostedSessionsLoading = enrolledSessionsLoading = false;
      _slotsGeneration++;
      _slotsRequest = null;
      _slotsLoadedAt = null;
      slotsLoading = false;
      slotsLoadingMore = false;
      slotAttendees = {};
      participationRevision++;
      unawaited(_refreshAfterSlotMutation(mutation));
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

  Future<void> _refreshAfterSlotMutation(int mutation) async {
    try {
      switch (_activeTab) {
        case MentorshipTab.mentors:
          return;
        case MentorshipTab.slots:
          await loadSlots();
        case MentorshipTab.mySessions:
          await loadMySessions();
      }
      if (_disposed || mutation != _slotMutationGeneration || error == null) {
        return;
      }
    } on Object {
      if (_disposed || mutation != _slotMutationGeneration) return;
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

  Future<void> refreshActiveTab() => Future.wait<void>([
    switch (_activeTab) {
      MentorshipTab.mentors => loadMentors(),
      MentorshipTab.slots => loadSlots(),
      MentorshipTab.mySessions => loadMySessions(),
    },
    loadMyProfile(),
  ]);

  void invalidate() {
    if (_disposed) return;
    _slotMutationGeneration++;
    participationRevision++;
    _mentorSearchTimer?.cancel();
    _slotSearchTimer?.cancel();
    _mentorSearchTimer = _slotSearchTimer = null;
    _mentorsRequest = _slotsRequest = _sessionsRequest = _profileRequest = null;
    _mentorsLoadedAt = _slotsLoadedAt = _sessionsLoadedAt = _profileLoadedAt =
        null;
    _mentorsGeneration++;
    _slotsGeneration++;
    _sessionsGeneration++;
    _profileGeneration++;
    mentorsLoading = false;
    mentorsLoadingMore = false;
    slotsLoading = false;
    slotsLoadingMore = false;
    sessionsLoading = false;
    hostedSessionsLoading = enrolledSessionsLoading = false;
    myProfileLoading = false;
    attendeesLoading = false;
    loading = false;
    error = null;
    notifyListeners();
  }

  void selectTab(MentorshipTab tab) {
    if (_disposed || _activeTab == tab) return;
    if (_mentorSearchTimer != null) {
      _mentorSearchTimer!.cancel();
      _mentorSearchTimer = null;
      mentorsLoading = false;
    }
    if (_slotSearchTimer != null) {
      _slotSearchTimer!.cancel();
      _slotSearchTimer = null;
      slotsLoading = false;
    }
    _activeTab = tab;
    notifyListeners();
    unawaited(loadInitial());
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
    _mentorSearchTimer?.cancel();
    _slotSearchTimer?.cancel();
    super.dispose();
  }
}
