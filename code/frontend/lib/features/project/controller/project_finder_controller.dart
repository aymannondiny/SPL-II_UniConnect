import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/model/project_models.dart';

enum ProjectFinderTab { open, mine, applied }

class ProjectFinderController extends ChangeNotifier {
  ProjectFinderController(this.repository);

  final ProjectRepository repository;
  bool _disposed = false;
  ProjectFinderTab activeTab = ProjectFinderTab.open;
  ProjectBrowseFilters filters = const ProjectBrowseFilters();
  String? error;
  bool mutating = false;

  List<ProjectListing> openProjects = [];
  int openTotal = 0;
  int _openPage = 0;
  bool openLoading = true;
  bool openLoadingMore = false;
  int _openGeneration = 0;

  List<ProjectListing> myProjects = [];
  int myTotal = 0;
  int _myPage = 0;
  bool myLoading = false;
  bool myLoadingMore = false;
  int _myGeneration = 0;

  List<AppliedProject> applications = [];
  int appliedTotal = 0;
  int _appliedPage = 0;
  bool appliedLoading = false;
  bool appliedLoadingMore = false;
  int _appliedGeneration = 0;

  bool get canLoadMoreOpen => openProjects.length < openTotal;
  bool get canLoadMoreMine => myProjects.length < myTotal;
  bool get canLoadMoreApplied => applications.length < appliedTotal;

  void selectTab(ProjectFinderTab tab) {
    if (_disposed || activeTab == tab) return;
    activeTab = tab;
    notifyListeners();
    refreshActiveTab();
  }

  Future<void> refreshActiveTab() async {
    switch (activeTab) {
      case ProjectFinderTab.open:
        await loadOpen();
      case ProjectFinderTab.mine:
        await loadMine();
      case ProjectFinderTab.applied:
        await loadApplied();
    }
  }

  Future<void> loadOpen({bool more = false}) async {
    if (_disposed || (more && (openLoading || openLoadingMore))) return;
    final generation = ++_openGeneration;
    final page = more ? _openPage + 1 : 0;
    openLoading = !more;
    openLoadingMore = more;
    error = null;
    notifyListeners();
    try {
      final result = await repository.browse(filters, page);
      if (_disposed || generation != _openGeneration) return;
      openProjects = more ? [...openProjects, ...result.items] : result.items;
      openTotal = result.totalElements;
      _openPage = page;
    } on AuthFailure catch (failure) {
      if (_disposed || generation != _openGeneration) return;
      error = failure.message;
    } finally {
      if (!_disposed && generation == _openGeneration) {
        openLoading = false;
        openLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void updateFilters(ProjectBrowseFilters next) {
    if (_disposed) return;
    filters = next;
    unawaited(loadOpen());
  }

  void clearFilters() => updateFilters(const ProjectBrowseFilters());

  Future<void> loadMine({bool more = false}) async {
    if (_disposed || (more && (myLoading || myLoadingMore))) return;
    final generation = ++_myGeneration;
    final page = more ? _myPage + 1 : 0;
    myLoading = !more;
    myLoadingMore = more;
    error = null;
    notifyListeners();
    try {
      final result = await repository.mine(page);
      if (_disposed || generation != _myGeneration) return;
      myProjects = more ? [...myProjects, ...result.items] : result.items;
      myTotal = result.totalElements;
      _myPage = page;
    } on AuthFailure catch (failure) {
      if (_disposed || generation != _myGeneration) return;
      error = failure.message;
    } finally {
      if (!_disposed && generation == _myGeneration) {
        myLoading = false;
        myLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadApplied({bool more = false}) async {
    if (_disposed || (more && (appliedLoading || appliedLoadingMore))) return;
    final generation = ++_appliedGeneration;
    final page = more ? _appliedPage + 1 : 0;
    appliedLoading = !more;
    appliedLoadingMore = more;
    error = null;
    notifyListeners();
    try {
      final result = await repository.applied(page);
      if (_disposed || generation != _appliedGeneration) return;
      applications = more ? [...applications, ...result.items] : result.items;
      appliedTotal = result.totalElements;
      _appliedPage = page;
    } on AuthFailure catch (failure) {
      if (_disposed || generation != _appliedGeneration) return;
      error = failure.message;
    } finally {
      if (!_disposed && generation == _appliedGeneration) {
        appliedLoading = false;
        appliedLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<ProjectListing?> createProject(ProjectRequestData request) async {
    final result = await _mutate(() => repository.create(request));
    if (result != null) {
      await Future.wait([loadMine(), loadOpen()]);
    }
    return result;
  }

  Future<ProjectListing?> updateProject(
    int projectId,
    ProjectRequestData request,
  ) async {
    final result = await _mutate(() => repository.update(projectId, request));
    if (result != null) await Future.wait([loadMine(), loadOpen()]);
    return result;
  }

  Future<bool> apply(int projectId, String message) async {
    final result = await _mutate(() => repository.apply(projectId, message));
    if (result == null) return false;
    await Future.wait([loadOpen(), loadApplied()]);
    return true;
  }

  Future<bool> closeProject(int projectId) async =>
      _projectAction(() => repository.close(projectId));

  Future<bool> reopenProject(int projectId) async =>
      _projectAction(() => repository.reopen(projectId));

  Future<bool> deleteProject(int projectId) async {
    final success = await _mutate(() async {
      await repository.delete(projectId);
      return true;
    });
    if (success != null) await Future.wait([loadMine(), loadOpen()]);
    return success ?? false;
  }

  Future<bool> reviewApplication(int applicationId, String decision) async {
    final result = await _mutate(
      () => repository.review(applicationId, decision),
    );
    if (result == null) return false;
    await Future.wait([loadMine(), loadOpen()]);
    return true;
  }

  Future<bool> _projectAction(Future<ProjectListing> Function() action) async {
    final result = await _mutate(action);
    if (result == null) return false;
    await Future.wait([loadMine(), loadOpen()]);
    return true;
  }

  Future<T?> _mutate<T>(Future<T> Function() action) async {
    if (_disposed || mutating) return null;
    mutating = true;
    error = null;
    notifyListeners();
    try {
      return await action();
    } on AuthFailure catch (failure) {
      if (!_disposed) error = failure.message;
      return null;
    } finally {
      if (!_disposed) {
        mutating = false;
        notifyListeners();
      }
    }
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  void invalidate() {
    _openGeneration++;
    _myGeneration++;
    _appliedGeneration++;
    openLoading = false;
    openLoadingMore = false;
    myLoading = false;
    myLoadingMore = false;
    appliedLoading = false;
    appliedLoadingMore = false;
    mutating = false;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
