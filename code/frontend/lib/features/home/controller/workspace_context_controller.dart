import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/model/club_workspace_context.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';

/// Owns session context selection; navigation changes only after server success.
class WorkspaceContextController extends ChangeNotifier {
  WorkspaceContextController(this.repository, this.role) {
    if (role == 'SYSTEM_ADMIN') {
      selected = const ClubWorkspaceContext(
        contextType: 'SYSTEM_ADMINISTRATION',
      );
    }
  }

  final ClubRepository repository;
  final String role;
  List<ClubWorkspaceContext> available = const [];
  ClubWorkspaceContext selected = const ClubWorkspaceContext(
    contextType: 'PERSONAL',
  );
  bool busy = false;
  bool loaded = false;
  String? error;
  bool _disposed = false;

  WorkspaceAccess get access => WorkspaceAccess(role: role, context: selected);

  Future<void> load() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = await repository.workspaceContexts();
      if (_disposed) return;
      available = snapshot.available.where(_eligible).toList();
      selected = available.firstWhere(
        (item) => item.key == snapshot.active.key,
        orElse: () => ClubWorkspaceContext(
          contextType: role == 'SYSTEM_ADMIN'
              ? 'SYSTEM_ADMINISTRATION'
              : 'PERSONAL',
        ),
      );
      // Administration is the default landing experience for system admins.
      if (role == 'SYSTEM_ADMIN' &&
          snapshot.active.contextType != 'SYSTEM_ADMINISTRATION') {
        final admin = available.where(
          (item) => item.contextType == 'SYSTEM_ADMINISTRATION',
        );
        if (admin.isNotEmpty) {
          await repository.selectContext('SYSTEM_ADMINISTRATION');
          if (_disposed) return;
          selected = admin.first;
        }
      }
      loaded = true;
    } on AuthFailure catch (failure) {
      error = failure.message;
    } on Object {
      error =
          'Unable to load workspace contexts. Retry to access your workspaces.';
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  bool _eligible(ClubWorkspaceContext item) =>
      (role != 'SYSTEM_ADMIN' && item.contextType == 'PERSONAL') ||
      (role == 'SYSTEM_ADMIN' && item.contextType == 'SYSTEM_ADMINISTRATION') ||
      WorkspaceAccess(role: role, context: item).club;

  Future<bool> select(String key) async {
    if (busy || role == 'SYSTEM_ADMIN') return false;
    final options = available.where((item) => item.key == key);
    if (options.isEmpty) return false;
    final target = options.first;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await repository.selectContext(
        target.contextType,
        assignmentId: target.assignmentId,
      );
      if (_disposed) return false;
      selected = target;
      return true;
    } on AuthFailure catch (failure) {
      error = failure.message;
      return false;
    } on Object {
      error = 'Unable to switch workspace. Your previous workspace is still selected.';
      return false;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
