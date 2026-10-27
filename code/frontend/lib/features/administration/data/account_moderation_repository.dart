import 'package:uniconnect/core/network/authenticated_json_client.dart';
import 'package:uniconnect/core/network/paged_loader.dart';
import 'package:uniconnect/core/network/response_parser.dart';
import 'package:uniconnect/features/administration/model/moderated_account.dart';

class AccountModerationRepository {
  AccountModerationRepository(this.api);
  final AuthenticatedJsonClient api;

  Future<({List<ModeratedAccount> items, int total})> search({
    int page = 0,
    String search = '',
    String role = '',
    String status = '',
  }) async {
    final data = await api.request(
      Uri(
        path: '/api/v1/admin/accounts',
        queryParameters: {
          'page': '$page',
          'size': '20',
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (role.isNotEmpty) 'role': role,
          if (status.isNotEmpty) 'status': status,
        },
      ).toString(),
    );
    return parseResponse(
      () => (
        items: (data['items'] as List)
            .map(
              (row) => ModeratedAccount.fromJson(row as Map<String, dynamic>),
            )
            .toList(),
        total: (data['totalElements'] as num).toInt(),
      ),
      resource: 'accounts',
    );
  }

  Future<ModeratedAccount> detail(int id) async {
    final data = await api.request('/api/v1/admin/accounts/$id');
    return parseResponse(
      () => ModeratedAccount.fromJson(data),
      resource: 'account',
    );
  }

  Future<void> transition(
    int id, {
    required bool suspend,
    required String reason,
  }) async {
    await api.request(
      '/api/v1/admin/accounts/$id/${suspend ? 'suspend' : 'restore'}',
      method: 'POST',
      body: {'reason': reason.trim(), 'confirm': true},
    );
  }

  Future<List<Map<String, dynamic>>> audit(int id) async {
    return loadAllPages((page) async {
      final data = await api.request(
        '/api/v1/admin/accounts/$id/audit?page=$page&size=20',
      );
      return parseResponse(
        () => (
          items: (data['items'] as List).cast<Map<String, dynamic>>(),
          total: (data['totalElements'] as num).toInt(),
        ),
        resource: 'account history',
      );
    });
  }
}
