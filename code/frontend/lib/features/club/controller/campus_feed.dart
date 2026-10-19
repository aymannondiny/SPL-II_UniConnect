import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../model/club_page.dart';

/// Retains successful pages on load-more failure and ignores obsolete responses.
class CampusFeed<T> extends ChangeNotifier {
  CampusFeed(this.fetch);
  final Future<ClubPage<T>> Function(int page) fetch;
  List<T> items = [];
  int total = 0;
  int _page = 0;
  int _generation = 0;
  bool loading = false;
  bool _disposed = false;
  String? error;
  bool get hasMore => items.length < total;

  Future<void> load({bool reset = true}) async {
    if (_disposed || (!reset && (loading || !hasMore))) return;
    final generation = ++_generation;
    if (reset) {
      items = [];
      total = 0;
      _page = 0;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await fetch(_page);
      if (_disposed || generation != _generation) return;
      items = [...items, ...result.items];
      total = result.items.isEmpty ? items.length : result.total;
      _page++;
    } on AuthFailure catch (failure) {
      if (_disposed || generation != _generation) return;
      error = failure.message;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
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
