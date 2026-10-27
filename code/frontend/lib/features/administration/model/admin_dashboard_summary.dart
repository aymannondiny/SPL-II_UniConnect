class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalUsers,
    required this.activeClubs,
    required this.publishedPosts,
    required this.openReports,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) =>
      AdminDashboardSummary(
        totalUsers: (json['totalUsers'] as num).toInt(),
        activeClubs: (json['activeClubs'] as num).toInt(),
        publishedPosts: (json['publishedPosts'] as num).toInt(),
        openReports: (json['openReports'] as num).toInt(),
      );

  final int totalUsers;
  final int activeClubs;
  final int publishedPosts;
  final int openReports;
}
