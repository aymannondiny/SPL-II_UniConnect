import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/profile/data/profile_repository.dart';
import 'package:uniconnect/features/profile/model/academic_catalog.dart';
import 'package:uniconnect/features/profile/model/personal_profile.dart';

/// Coordinates onboarding and editing without discarding a saved profile on retry.
class ProfileController extends ChangeNotifier {
  ProfileController(this.repository);
  final ProfileRepository repository;
  bool loading = true;
  bool saving = false;
  bool catalogLoading = false;
  bool _visibilityLoaded = false;
  bool _editDataReady = false;
  bool _editRequested = false;
  bool loaded = false;
  bool readyForHome = false;
  bool _disposed = false;
  PersonalProfile? profile;
  AcademicCatalog? catalog;
  String visibility = 'CONNECTIONS_ONLY';
  String? error;

  /// The home page only needs the profile. The academic catalog and privacy
  /// choice are fetched when onboarding or profile editing actually needs them.
  bool get editDataReady => _editDataReady;

  Future<void> reloadCatalog() async {
    if (catalogLoading || saving) return;
    catalogLoading = true;
    error = null;
    _notify();
    try {
      catalog = await repository.catalog();
    } on AuthFailure catch (failure) {
      error = failure.message;
    } on Object {
      error = 'Unable to reload academic options. Please retry.';
    } finally {
      catalogLoading = false;
      _notify();
    }
  }

  Future<void> load() async {
    loading = true;
    loaded = false;
    _visibilityLoaded = false;
    _editDataReady = false;
    error = null;
    _notify();
    try {
      profile = await repository.load();
      loaded = true;
      readyForHome = profile != null;
      // New members need the catalog to complete onboarding. Returning
      // members can enter the workspace without waiting for edit-only data.
      if (profile == null || _editRequested) {
        _editRequested = false;
        await _fetchEditData();
      }
    } on AuthFailure catch (failure) {
      error = failure.message;
    } on Object {
      error = 'Unable to read your profile. Please retry.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> prepareEditing() async {
    if (!loaded) {
      _editRequested = true;
      return;
    }
    if (editDataReady || catalogLoading || saving) return;
    await _fetchEditData();
  }

  Future<void> _fetchEditData() async {
    if (editDataReady || catalogLoading || saving) return;
    catalogLoading = true;
    error = null;
    _notify();
    try {
      final values = await Future.wait<Object>([
        catalog == null ? repository.catalog() : Future.value(catalog!),
        profile == null || _visibilityLoaded
            ? Future.value(visibility)
            : repository.visibility(),
      ]);
      catalog = values[0] as AcademicCatalog;
      visibility = values[1] as String;
      if (profile != null) _visibilityLoaded = true;
      _editDataReady = true;
    } on AuthFailure catch (failure) {
      error = failure.message;
    } on Object {
      error = 'Unable to load profile options. Please retry.';
    } finally {
      catalogLoading = false;
      _notify();
    }
  }

  Future<bool> save(
    String role,
    Map<String, dynamic> fields,
    String nextVisibility,
  ) async {
    if (saving) return false;
    saving = true;
    error = null;
    _notify();
    var profileSaved = false;
    try {
      profile = await repository.save(role, fields);
      profileSaved = true;
      // Privacy is a separate transaction. Keep the form open if it fails.
      await repository.saveVisibility(nextVisibility);
      visibility = nextVisibility;
      _visibilityLoaded = true;
      _editDataReady = catalog != null;
      readyForHome = true;
      return true;
    } on AuthFailure catch (failure) {
      error = profileSaved
          ? 'Your profile was saved, but privacy could not be updated. ${failure.message}'
          : failure.message;
      return false;
    } on Object {
      error = profileSaved
          ? 'Your profile was saved. Retry to finish saving privacy.'
          : 'Unable to save your profile. Please retry.';
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
