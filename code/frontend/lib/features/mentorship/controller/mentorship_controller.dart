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
