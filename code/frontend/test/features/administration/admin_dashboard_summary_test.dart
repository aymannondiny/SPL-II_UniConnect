import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/administration/model/admin_dashboard_summary.dart';

void main() {
  test('maps every authoritative dashboard count', () {
    final summary = AdminDashboardSummary.fromJson({
      'totalUsers': 38,
      'activeClubs': 6,
      'publishedPosts': 14,
      'openReports': 3,
    });

    expect(summary.totalUsers, 38);
    expect(summary.activeClubs, 6);
    expect(summary.publishedPosts, 14);
    expect(summary.openReports, 3);
  });

  test('rejects missing or malformed fields instead of substituting zero', () {
    expect(
      () => AdminDashboardSummary.fromJson({
        'totalUsers': 38,
        'activeClubs': 6,
        'publishedPosts': 14,
      }),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => AdminDashboardSummary.fromJson({
        'totalUsers': '38',
        'activeClubs': 6,
        'publishedPosts': 14,
        'openReports': 3,
      }),
      throwsA(isA<TypeError>()),
    );
  });
}
