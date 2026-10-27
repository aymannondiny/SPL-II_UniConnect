import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Only imported by preview and tests. Never used by the production entry point.
class CampusFixtureApi {
  CampusFixtureApi({this.role = 'STUDENT', this.clubRole}) {
    client = MockClient(_respond);
  }
  final String role;
  final String? clubRole;
  Map<String, Object?> activeContext = {'contextType': 'PERSONAL'};
  late final http.Client client;
  final now = DateTime.now().toUtc();

  final clubs = [
    {
      'id': 1,
      'clubName': 'Programming Club',
      'category': 'Technology',
      'description': 'Build together. Learn through workshops, programming contests and projects with your campus community.',
      'contactEmail': 'programming@example.org',
      'status': 'ACTIVE',
    },
    {
      'id': 2,
      'clubName': 'Cultural Club',
      'category': 'Arts & culture',
      'description': 'A space for music, stories and creative expression. Meet the people who bring campus to life.',
      'contactEmail': null,
      'status': 'ACTIVE',
    },
    {
      'id': 3,
      'clubName': 'Career Club',
      'category': 'Professional development',
      'description': 'Connect with alumni, share experiences and prepare for your next step beyond campus.',
      'contactEmail': null,
      'status': 'PUBLISHING_SUSPENDED',
    },
  ];

  List<Map<String, Object?>> get announcements => [
    {
      'id': 11,
      'clubId': 1,
      'clubName': 'Programming Club',
      'title': 'Intra-IUT contest registration is open',
      'content': 'Teams of three can register until Friday. Bring your student ID to the first practice session. New to competitive programming? Join our beginner practice circle before the contest.',
      'priority': 'IMPORTANT',
      'publishedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 12,
      'clubId': 2,
      'clubName': 'Cultural Club',
      'title': 'Open mic night has a new home',
      'content': 'Same time, new venue: the student lounge. Share a song, a poem or a story. Everyone is welcome.',
      'priority': 'NORMAL',
      'publishedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  List<Map<String, Object?>> get events => [
    _event(21, 1, 'Campus coding sprint', 2, 'Computer Lab 1'),
    _event(22, 2, 'An evening of music & stories', 4, 'Student lounge'),
    _event(23, 3, 'Alumni resume clinic', 7, 'Seminar room'),
    _event(24, 1, 'Introduction to Flutter', -7, 'Computer Lab 2'),
  ];

  Map<String, Object?> _event(
    int id,
    int clubId,
    String title,
    int days,
    String location,
  ) => {
    'id': id,
    'clubId': clubId,
    'clubName': clubs[clubId - 1]['clubName'],
    'title': title,
    'description': 'Meet your campus community for a practical, welcoming session. Bring your curiosity and learn something together.',
    'location': location,
    'registrationUrl': 'https://example.org/register/$id',
    'registrationDeadline': now.add(Duration(days: days - 1)).toIso8601String(),
    'startsAt': now.add(Duration(days: days)).toIso8601String(),
    'endsAt': now.add(Duration(days: days, hours: 2)).toIso8601String(),
  };

  Future<http.Response> _respond(http.Request request) async {
    final path = request.url.path;
    final available = <Map<String, Object?>>[
      {'contextType': 'PERSONAL'},
      if (role == 'SYSTEM_ADMIN') {'contextType': 'SYSTEM_ADMINISTRATION'},
      if (role == 'STUDENT' && clubRole != null)
        {
          'contextType': 'CLUB',
          'assignmentId': 10,
          'clubId': 1,
          'clubName': 'Programming Club',
          'clubRole': clubRole,
        },
    ];
    if (path == '/api/v1/auth/contexts' ||
        path == '/api/v1/auth/contexts/active') {
      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        activeContext = available.firstWhere(
          (item) =>
              item['contextType'] == body['contextType'] &&
              item['assignmentId'] == body['assignmentId'],
        );
      }
      return http.Response(
        jsonEncode({
          'activeContext': activeContext,
          'availableContexts': available,
        }),
        200,
      );
    }
    if (path.contains('/publications/announcements')) {
      return http.Response(
        jsonEncode({
          'items': announcements
              .where((item) => item['clubId'] == int.parse(path.split('/')[4]))
              .toList(),
          'totalElements': announcements
              .where((item) => item['clubId'] == int.parse(path.split('/')[4]))
              .length,
          'page': 0,
          'size': 50,
        }),
        200,
      );
    }
    if (path.contains('/publications/events')) {
      return http.Response(
        jsonEncode({
          'items': events
              .where((item) => item['clubId'] == int.parse(path.split('/')[4]))
              .toList(),
          'totalElements': events
              .where((item) => item['clubId'] == int.parse(path.split('/')[4]))
              .length,
          'page': 0,
          'size': 50,
        }),
        200,
      );
    }

    final query = request.url.queryParameters;
    final clubId = int.tryParse(query['clubId'] ?? '');
    List<Map<String, Object?>> rows;
    if (path == '/api/v1/clubs') {
      final search = (query['search'] ?? '').toLowerCase();
      rows = clubs
          .where(
            (club) => '${club['clubName']} ${club['category']}'
                .toLowerCase()
                .contains(search),
          )
          .toList();
    } else if (RegExp(r'^/api/v1/clubs/\d+$').hasMatch(path)) {
      return _detail(clubs, int.parse(path.split('/').last));
    } else if (path == '/api/v1/announcements') {
      rows = announcements
          .where((item) => clubId == null || item['clubId'] == clubId)
          .toList();
    } else if (path.startsWith('/api/v1/announcements/')) {
      return _detail(announcements, int.parse(path.split('/').last));
    } else if (path == '/api/v1/events' || path.endsWith('/events/history')) {
      final history = path.endsWith('/history');
      final filter = history ? int.parse(path.split('/')[4]) : clubId;
      rows = events.where((item) {
        final starts = DateTime.parse(item['startsAt'] as String);
        return (filter == null || item['clubId'] == filter) &&
            (history ? starts.isBefore(now) : starts.isAfter(now)) &&
            query['timing'] != 'ACTIVE';
      }).toList();
    } else if (path.startsWith('/api/v1/events/')) {
      return _detail(events, int.parse(path.split('/').last));
    } else {
      return http.Response('{}', 404);
    }
    final page = int.parse(query['page'] ?? '0');
    final size = int.parse(query['size'] ?? '12');
    return http.Response(
      jsonEncode({
        'items': rows.skip(page * size).take(size).toList(),
        'totalElements': rows.length,
        'page': page,
        'size': size,
      }),
      200,
    );
  }

  http.Response _detail(List<Map<String, Object?>> rows, int id) {
    final matches = rows.where((item) => item['id'] == id);
    return matches.isEmpty
        ? http.Response('{}', 404)
        : http.Response(jsonEncode(matches.first), 200);
  }
}
