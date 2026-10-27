import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Isolated visual-QA data. Production never imports this transport.
class WorkflowFixtureApi {
  late final client = MockClient(_respond);
  final List<http.Request> requests = [];
  String accountStatus = 'ACTIVE';
  String reportStatus = 'SUBMITTED';
  Map<String, dynamic>? decision;

  Map<String, dynamic> project(int id) => {
    'id': id,
    'creatorUserId': 2,
    'creatorDisplayName': 'Nadia Rahman',
    'creatorDepartmentCode': 'CSE',
    'title': 'Campus collaboration project $id',
    'description': 'Build a useful campus tool with a small team. We are looking for students who enjoy thoughtful design and reliable software.',
    'teamSizeLimit': 4,
    'membershipCount': 2,
    'vacancies': 2,
    'applicationDeadline': '2026-12-31',
    'status': 'OPEN',
    'availability': 'AVAILABLE',
    'canApply': true,
    'skills': [
      {'id': 7, 'name': 'Flutter', 'required': true},
    ],
  };

  Map<String, dynamic> get account => {
    'userId': 2,
    'fullName': 'Nadia Rahman',
    'email': 'nadia@iut-dhaka.edu',
    'platformRole': 'STUDENT',
    'accountStatus': accountStatus,
  };

  Map<String, dynamic> get report => {
    'id': 12,
    'targetType': 'PROJECT',
    'targetId': 1,
    'targetLabel': 'Campus collaboration project 1',
    'reason':
        'Please review this listing for misleading application requirements.',
    'status': reportStatus,
    'submittedAt': '2026-10-25T10:00:00',
    'reviewerId': reportStatus == 'SUBMITTED' ? null : 1,
    'resolutionSummary': decision?['resolutionSummary'],
  };

  Map<String, dynamic> page(List<Object?> items, {int? total}) => {
    'items': items,
    'page': 0,
    'size': 20,
    'totalElements': total ?? items.length,
  };

  http.Response _json(Object data, [int status = 200]) => http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> _respond(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (path == '/api/v1/auth/contexts/active') return _json({});
    if (path == '/api/v1/admin/clubs' ||
        path == '/api/v1/admin/clubs/eligible-students') {
      return _json(page([]));
    }
    if (path == '/api/v1/admin/club-requests') return _json([]);
    if (path == '/api/v1/profile/academic-options' ||
        path == '/api/v1/admin/academics') {
      return _json({
        'departments': [],
        'programmes': [],
        'programmeDegrees': [],
        'degrees': [],
      });
    }
    if (path == '/api/v1/projects') {
      return _json(page([for (var id = 1; id <= 4; id++) project(id)]));
    }
    if (path == '/api/v1/projects/mine' || path == '/api/v1/projects/applied') {
      return _json(page([]));
    }
    if (RegExp(r'^/api/v1/projects/\d+$').hasMatch(path)) {
      return _json(project(int.parse(path.split('/').last)));
    }
    if (path.endsWith('/members')) {
      return _json([
        {
          'id': 1,
          'userId': 2,
          'displayName': 'Nadia Rahman',
          'role': 'CREATOR',
          'joinedAt': '2026-10-20T10:00:00',
        },
        {
          'id': 2,
          'userId': 3,
          'displayName': 'Arif Hasan',
          'role': 'TEAMMATE',
          'joinedAt': '2026-10-21T10:00:00',
        },
      ]);
    }
    if (path == '/api/v1/notifications') {
      return _json(
        page([
          for (final entry in [
            (1, 'PROJECT', 1, 'Project application update'),
            (2, 'REPORT', 12, 'Your report has an update'),
            (3, 'MENTORSHIP_SLOT', 1, 'Mentorship session updated'),
          ])
            {
              'id': entry.$1,
              'type': 'UPDATE',
              'referenceType': entry.$2,
              'referenceId': entry.$3,
              'title': entry.$4,
              'message': 'Open to see the latest details.',
              'createdAt': '2026-10-25T10:00:00',
              'readAt': null,
            },
        ]),
      );
    }
    if (path.startsWith('/api/v1/notifications/')) return _json({});
    if (path == '/api/v1/reports' && request.method == 'POST') {
      return _json(report, 201);
    }
    if (path == '/api/v1/reports' || path == '/api/v1/admin/reports') {
      return _json(page([report]));
    }
    if (path == '/api/v1/admin/reports/12/review') {
      reportStatus = 'UNDER_REVIEW';
    }
    if (path == '/api/v1/admin/reports/12/resolve') {
      decision = jsonDecode(request.body) as Map<String, dynamic>;
      reportStatus = decision!['outcome'] as String;
    }
    if (path.startsWith('/api/v1/admin/reports/12')) {
      return _json({
        ...report,
        'targetSnapshot':
            'Retained project title and requirements at submission.',
        'internalNotes': decision?['internalNotes'],
        'history': [
          {
            'eventType': 'SUBMITTED',
            'actorId': 2,
            'occurredAt': '2026-10-25T10:00:00',
          },
        ],
      });
    }
    if (path == '/api/v1/reports/12') return _json(report);
    if (path == '/api/v1/admin/accounts') return _json(page([account]));
    if (path == '/api/v1/admin/accounts/2/suspend') accountStatus = 'SUSPENDED';
    if (path == '/api/v1/admin/accounts/2/restore') accountStatus = 'ACTIVE';
    if (path == '/api/v1/admin/accounts/2/audit') {
      return _json(
        page([
          {
            'actionId': 17,
            'actionType': 'SUSPEND_ACCOUNT',
            'actorId': 1,
            'reason': 'Reviewed under account policy.',
            'occurredAt': '2026-10-25T11:00:00',
          },
        ]),
      );
    }
    if (path.startsWith('/api/v1/admin/accounts/2')) return _json(account);
    return _json({'message': 'No visual-QA fixture for this route.'}, 404);
  }
}
