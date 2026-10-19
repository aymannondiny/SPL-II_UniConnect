import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Isolated QA transport. Production main.dart never imports these fixtures.
class MemberFixtureApi {
  final requests = <http.Request>[];
  final Map<int, String> _status = {2: 'ACCEPTED', 3: 'PENDING', 4: 'PENDING'};
  final Map<int, bool> _outgoing = {2: false, 3: false, 4: true};
  late final http.Client client = MockClient(_handle);

  Map<String, dynamic> member(int id) => {
    'userId': id,
    'fullName': id == 2
        ? 'Nafisa Rahman'
        : id == 3
        ? 'Arif Hasan'
        : id == 4
        ? 'Farhana Akter'
        : 'Community Member $id',
    'platformRole': id.isEven ? 'ALUMNI' : 'STUDENT',
    'department': {'id': 1, 'name': 'Computer Science', 'code': 'CSE'},
    'programme': {
      'id': 1,
      'departmentId': 1,
      'name': 'Software Engineering',
      'code': 'SWE',
    },
    'detailsVisible': id != 3,
    if (_status.containsKey(id))
      'connection': {
        'id': id,
        'status': _status[id],
        'outgoing': _outgoing[id] ?? true,
      },
    if (id != 3)
      'details': {
        'bio': 'Building useful things and connecting with the university community.',
        'skills': ['Flutter', 'Java'],
        'interests': ['Design', 'Open source'],
        'sharedSkills': ['Flutter'],
        'sharedInterests': [],
        if (id.isEven)
          'alumni': {
            'graduationYear': 2024,
            'currentCompany': 'Campus Labs',
            'currentPosition': 'Software Engineer',
            'industry': 'Technology',
          }
        else
          'student': {
            'yearOfStudy': 3,
            'expectedGraduationYear': 2027,
            'projectAvailability': true,
            'mentorshipAvailability': true,
          },
      },
  };

  http.Response _json(Object value, [int status = 200]) => http.Response(
    jsonEncode(value),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    final query = request.url.queryParameters;
    if (path.endsWith('/academic-options')) {
      return _json({
        'departments': [
          {'id': 1, 'name': 'Computer Science', 'code': 'CSE'},
        ],
        'programmes': [],
        'degrees': [],
      });
    }
    if (path == '/api/v1/members') {
      var items = [for (var id = 2; id <= 26; id++) member(id)];
      final name = query['name']?.toLowerCase() ?? '';
      items = items
          .where((m) => (m['fullName'] as String).toLowerCase().contains(name))
          .toList();
      if (query['role']?.isNotEmpty == true) {
        items = items.where((m) => m['platformRole'] == query['role']).toList();
      }
      if (query['departmentId'] != null && query['departmentId'] != '1') {
        items = [];
      }
      if (query['company'] != null) {
        items = items
            .where(
              (m) =>
                  m['platformRole'] == 'ALUMNI' &&
                  'campus labs'.contains(query['company']!.toLowerCase()),
            )
            .toList();
      }
      if (query['graduationYear'] != null) {
        items = items
            .where(
              (m) =>
                  m['platformRole'] == 'ALUMNI' &&
                  query['graduationYear'] == '2024',
            )
            .toList();
      }
      if (query['skills'] != null &&
          query['skills']!
              .split(',')
              .any(
                (s) => !['flutter', 'java'].contains(s.trim().toLowerCase()),
              )) {
        items = [];
      }
      final page = int.parse(query['page'] ?? '0');
      final size = int.parse(query['size'] ?? '20');
      return _json({
        'items': items.skip(page * size).take(size).toList(),
        'totalElements': items.length,
        'page': page,
        'size': size,
      });
    }
    if (path.startsWith('/api/v1/members/')) {
      return _json(member(int.parse(path.split('/').last)));
    }
    if (path == '/api/v1/connections' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final id = body['receiverId'] as int;
      _status[id] = 'PENDING';
      _outgoing[id] = true;
      return _json({'id': id}, 201);
    }
    if (path == '/api/v1/connections') {
      final rows = _status.entries
          .where((entry) => entry.value == query['status'])
          .where(
            (entry) =>
                query['direction'] == 'ALL' ||
                _outgoing[entry.key] == (query['direction'] == 'OUTGOING'),
          )
          .map(
            (entry) => {
              'connection': {
                'id': entry.key,
                'status': entry.value,
                'introductoryMessage': '',
              },
              'otherUserId': entry.key,
              'fullName': member(entry.key)['fullName'],
            },
          )
          .where(
            (row) => (row['fullName'] as String).toLowerCase().contains(
              (query['name'] ?? '').toLowerCase(),
            ),
          )
          .toList();
      return _json({
        'items': rows,
        'totalElements': rows.length,
        'page': 0,
        'size': 50,
      });
    }
    if (path.startsWith('/api/v1/connections/') && request.method == 'POST') {
      final parts = path.split('/');
      final id = int.parse(parts[4]);
      if (parts.last == 'accept') {
        _status[id] = 'ACCEPTED';
      } else {
        _status.remove(id);
      }
      return _json({'id': id});
    }
    return _json({'message': 'Unsupported fixture endpoint'}, 404);
  }
}
