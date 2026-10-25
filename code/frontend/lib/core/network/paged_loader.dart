import 'package:uniconnect/features/authentication/model/auth_failure.dart';

/// Loads every server page without increasing the server's maximum page size.
Future<List<T>> loadAllPages<T>(
  Future<({List<T> items, int total})> Function(int page) load,
) async {
  final items = <T>[];
  for (var page = 0; ; page++) {
    final result = await load(page);
    items.addAll(result.items);
    if (items.length >= result.total) return items;
    if (result.items.isEmpty) {
      throw const AuthFailure(
        'The list changed while loading. Refresh to try again.',
      );
    }
  }
}
