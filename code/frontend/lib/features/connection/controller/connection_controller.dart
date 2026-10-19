import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../data/connection_repository.dart';
import '../model/connection_models.dart';
import '../model/member_filters.dart';

/// Coordinates list requests and rejects stale results after filter/navigation changes.
class ConnectionController extends ChangeNotifier {
  ConnectionController(this.repository);
  final ConnectionRepository repository;
  bool _disposed = false;
  int _connectionGeneration = 0;
  int _discoveryGeneration = 0;
  int _memberPage = 0;
  MemberFilters filters = const MemberFilters();
  bool loading = true;
  bool loadingMore = false;
  String? error;
  List<ConnectionRow> connected = [];
  List<ConnectionRow> incoming = [];
  List<ConnectionRow> outgoing = [];
  List<MemberProfile> members = [];
  int total = 0;

  void invalidate() {
    _connectionGeneration++;
    _discoveryGeneration++;
    loadingMore = false;
    error = null;
  }

  Future<void> load(String name) async {
    if (_disposed) return;
    final generation = ++_connectionGeneration;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        repository.connections('ACCEPTED', 'ALL', name),
        repository.connections('PENDING', 'INCOMING', name),
        repository.connections('PENDING', 'OUTGOING', name),
      ]);
      if (_disposed || generation != _connectionGeneration) return;
      connected = values[0];
      incoming = values[1];
      outgoing = values[2];
      loading = false;
      notifyListeners();
    } on AuthFailure catch (failure) {
      if (_disposed || generation != _connectionGeneration) return;
      error = failure.message;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String name, {bool more = false}) async {
    if (_disposed || (more && (loadingMore || loading))) return;
    final generation = ++_discoveryGeneration;
    final page = more ? _memberPage + 1 : 0;
    if (!more) {
      filters = filters.withName(name);
      members = [];
      total = 0;
    }
    loading = !more;
    loadingMore = more;
    error = null;
    notifyListeners();
    try {
      final result = await repository.members(filters, page);
      final received = result.items;
      if (_disposed || generation != _discoveryGeneration) return;
      members = more
          ? [
              ...members,
              ...received.where(
                (member) => !members.any((old) => old.id == member.id),
              ),
            ]
          : received;
      _memberPage = page;
      total = result.total;
      loading = false;
      loadingMore = false;
      notifyListeners();
    } on AuthFailure catch (failure) {
      if (_disposed || generation != _discoveryGeneration) return;
      error = failure.message;
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
