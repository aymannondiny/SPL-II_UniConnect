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
