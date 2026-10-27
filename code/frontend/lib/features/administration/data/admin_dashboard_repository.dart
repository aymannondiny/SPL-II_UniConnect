import 'package:uniconnect/core/network/authenticated_json_client.dart';
import 'package:uniconnect/core/network/response_parser.dart';
import 'package:uniconnect/features/administration/model/admin_dashboard_summary.dart';

abstract interface class AdminDashboardRepository {
  Future<AdminDashboardSummary> summary();
}

class ApiAdminDashboardRepository implements AdminDashboardRepository {
  ApiAdminDashboardRepository(this.api);

  final AuthenticatedJsonClient api;

  @override
  Future<AdminDashboardSummary> summary() async {
    final data = await api.request('/api/v1/admin/dashboard/summary');
    return parseResponse(
      () => AdminDashboardSummary.fromJson(data),
      resource: 'administration dashboard summary',
    );
  }
}
