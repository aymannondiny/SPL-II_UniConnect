class ConnectionRow {
  const ConnectionRow(this.connection, this.otherUserId, this.name);
  final ConnectionSummary connection;
  final int? otherUserId;
  final String name;
  factory ConnectionRow.fromJson(Map<String, dynamic> json) => ConnectionRow(
    ConnectionSummary.fromJson(json['connection'] as Map<String, dynamic>),
    (json['otherUserId'] as num?)?.toInt(),
    json['fullName'] as String? ?? 'Unavailable member',
  );
}

class ConnectionSummary {
  const ConnectionSummary(this.id, this.status, this.intro);
  final int id;
  final String status;
  final String intro;
  factory ConnectionSummary.fromJson(Map<String, dynamic> json) =>
      ConnectionSummary(
        (json['id'] as num).toInt(),
        json['status'] as String? ?? '',
        json['introductoryMessage'] as String? ?? '',
      );
}

class MemberProfile {
  const MemberProfile(
    this.id,
    this.name,
    this.headline,
    this.connection,
    this.detailsVisible,
    this.details,
  );
  final int id;
  final String name;
  final String headline;
  final MemberConnection? connection;
  final bool detailsVisible;
  final Map<String, dynamic>? details;
  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    final department = json['department'] as Map<String, dynamic>?;
    final programme = json['programme'] as Map<String, dynamic>?;
    final role = json['platformRole'] as String? ?? 'STUDENT';
    final details = json['detailsVisible'] == true
        ? json['details'] as Map<String, dynamic>?
        : null;
    final student = details?['student'] as Map<String, dynamic>?;
    final alumni = details?['alumni'] as Map<String, dynamic>?;
    final year = student?['yearOfStudy'];
    final detailLabel = role == 'ALUMNI'
        ? (alumni?['currentPosition'] ?? alumni?['currentCompany'])
        : (year == null ? null : 'Year $year');
    final headline =
        [
              role == 'ALUMNI' ? 'Alumni' : 'Student',
              department?['name'],
              programme?['name'],
              detailLabel,
            ]
            .whereType<Object>()
            .map((v) => '$v')
            .where((v) => v.isNotEmpty)
            .join(' · ');
    final connectionJson = json['connection'] as Map<String, dynamic>?;
    return MemberProfile(
      (json['userId'] as num).toInt(),
      json['fullName'] as String? ?? 'UniConnect member',
      headline,
      connectionJson == null ? null : MemberConnection.fromJson(connectionJson),
      json['detailsVisible'] as bool? ?? false,
      details,
    );
  }
}

class MemberConnection {
  const MemberConnection(this.status, this.outgoing);
  final String status;
  final bool outgoing;
  factory MemberConnection.fromJson(Map<String, dynamic> json) =>
      MemberConnection(
        json['status'] as String? ?? '',
        json['outgoing'] as bool? ?? false,
      );
}

/// One backend page of permitted member search results.
class MemberSearchPage {
  const MemberSearchPage({required this.items, required this.total});
  final List<MemberProfile> items;
  final int total;
  factory MemberSearchPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>)
        .map((item) => MemberProfile.fromJson(item as Map<String, dynamic>))
        .toList();
    return MemberSearchPage(
      items: items,
      total: (json['totalElements'] as num?)?.toInt() ?? items.length,
    );
  }
}
