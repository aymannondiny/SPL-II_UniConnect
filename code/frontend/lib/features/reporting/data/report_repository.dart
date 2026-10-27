import 'package:uniconnect/core/network/authenticated_json_client.dart';
import 'package:uniconnect/core/network/response_parser.dart';
import 'package:uniconnect/features/reporting/model/content_report.dart';

class ReportRepository {
  ReportRepository(this.api);
  final AuthenticatedJsonClient api;

  Future<({List<ContentReport> items, int total})> list({
    int page = 0,
    bool administration = false,
    String status = '',
    String targetType = '',
  }) async {
    final path = administration ? '/api/v1/admin/reports' : '/api/v1/reports';
    final data = await api.request(
      Uri(
        path: path,
        queryParameters: {
          'page': '$page',
          'size': '20',
          if (status.isNotEmpty && administration) 'status': status,
          if (targetType.isNotEmpty && administration) 'targetType': targetType,
        },
      ).toString(),
    );
    return parseResponse(
      () => (
        items: (data['items'] as List)
            .map((row) => ContentReport.fromJson(row as Map<String, dynamic>))
            .toList(),
        total: (data['totalElements'] as num).toInt(),
      ),
      resource: 'reports',
    );
  }

  Future<ContentReport> detail(int id, {bool administration = false}) async {
    final prefix = administration ? '/api/v1/admin/reports' : '/api/v1/reports';
    final data = await api.request('$prefix/$id');
    return parseResponse(
      () => ContentReport.fromJson(data),
      resource: 'report',
    );
  }

  Future<void> submit(String type, int id, String reason) async {
    await api.request(
      '/api/v1/reports',
      method: 'POST',
      body: {'targetType': type, 'targetId': id, 'reason': reason.trim()},
    );
  }

  Future<void> review(int id) async {
    await api.request('/api/v1/admin/reports/$id/review', method: 'POST');
  }

  Future<void> resolve(int id, Map<String, dynamic> decision) async {
    await api.request(
      '/api/v1/admin/reports/$id/resolve',
      method: 'POST',
      body: decision,
    );
  }
}
