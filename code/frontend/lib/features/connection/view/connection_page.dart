import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

/// Connections and member discovery, backed by the authenticated REST APIs.
class ConnectionPage extends StatefulWidget {
  const ConnectionPage({
    required this.session,
    this.initialDiscovery = false,
    this.onOpenMessages,
    super.key,
  });
  final SessionController session;
  final bool initialDiscovery;
  final VoidCallback? onOpenMessages;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  late final ApiClient _client;
  final _search = TextEditingController();
  final _discoverySearch = TextEditingController();
  int _tab = 0;
  bool _discover = false;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<_ConnectionRow> _connected = [];
  List<_ConnectionRow> _incoming = [];
  List<_ConnectionRow> _outgoing = [];
  List<_Member> _members = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _discover = widget.initialDiscovery;
    _discover ? _searchMembers() : _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _discoverySearch.dispose();
    _client.close();
    super.dispose();
  }

  Future<Map<String, String>> get _headers async => {
    'Authorization': 'Bearer ${await widget.session.accessToken()}',
  };

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() send, {
    Set<int> accepted = const {200},
  }) async {
    try {
      final response = await send().timeout(const Duration(seconds: 20));
      if (!accepted.contains(response.statusCode)) {
        if (response.statusCode == 401) {
          widget.session.expire();
          throw const AuthFailure(
            'Your session has ended. Please log in again.',
            sessionEnded: true,
          );
        }
        String message = switch (response.statusCode) {
          400 => 'Please check the request details and try again.',
          403 => 'You cannot perform this action for that connection.',
          404 => 'That member or connection is no longer available.',
          409 => 'That request conflicts with the current connection status. Refresh and try again.',
          _ => 'Unable to reach the connections service. Please retry.',
        };
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['message'] is String &&
              (response.statusCode == 400 || response.statusCode == 409)) {
            message = body['message'] as String;
          }
        } on Object {
          /* Keep the safe local error. */
        }
        throw AuthFailure(message);
      }
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw const AuthFailure('The request timed out. Please try again.');
    } on http.ClientException {
      throw const AuthFailure(
        'Cannot reach UniConnect. Check your connection and retry.',
      );
    } on FormatException {
      throw const AuthFailure(
        'The server returned an invalid response. Please retry.',
      );
    }
  }

  Future<List<_ConnectionRow>> _list(String status, String direction) async {
    final path = Uri(
      path: '/api/v1/connections',
      queryParameters: {
        'status': status,
        'direction': direction,
        'sort': 'NAME',
        'page': '0',
        'size': '50',
        if (_search.text.trim().isNotEmpty && !_discover)
          'name': _search.text.trim(),
      },
    ).toString();
    final json = await _request(
      () async => _client.get(path, headers: await _headers),
    );
    return (json['items'] as List<dynamic>)
        .map((item) => _ConnectionRow.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        _list('ACCEPTED', 'ALL'),
        _list('PENDING', 'INCOMING'),
        _list('PENDING', 'OUTGOING'),
      ]);
      if (!mounted) return;
      setState(() {
        _connected = values[0];
        _incoming = values[1];
        _outgoing = values[2];
        _loading = false;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = failure.message;
        _loading = false;
      });
    }
  }

  Future<void> _searchMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final path = Uri(
        path: '/api/v1/members',
        queryParameters: {
          'name': _discoverySearch.text.trim(),
          'sort': 'NAME_ASC',
          'page': '0',
          'size': '20',
        },
      ).toString();
      final json = await _request(
        () async => _client.get(path, headers: await _headers),
      );
      if (!mounted) return;
      setState(() {
        _members = (json['items'] as List<dynamic>)
            .map((item) => _Member.fromJson(item as Map<String, dynamic>))
            .toList();
        _total = (json['totalElements'] as num?)?.toInt() ?? _members.length;
        _loading = false;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = failure.message;
        _loading = false;
      });
    }
  }

  void _showDiscover(bool discover) {
    if (_discover == discover || _busy) return;
    setState(() {
      _discover = discover;
      _error = null;
    });
    if (discover) {
      _searchMembers();
    } else {
      _load();
    }
  }

  Future<void> _act(_ConnectionRow row, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _request(
        () async => _client.post(
          '/api/v1/connections/${row.connection.id}/$action',
          headers: await _headers,
        ),
      );
      await _load();
      if (mounted) {
        _toast(switch (action) {
          'accept' => 'Connection accepted.',
          'reject' => 'Request declined.',
          'cancel' => 'Request cancelled.',
          _ => 'Connection removed.',
        });
      }
    } on AuthFailure catch (failure) {
      if (mounted) _toast(failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send(_Member member) async {
    final message = TextEditingController();
    final intro = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect with ${member.name}'),
        content: TextField(
          controller: message,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add an introduction (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, message.text.trim()),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    message.dispose();
    if (intro == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _request(
        () async => _client.post(
          '/api/v1/connections',
          headers: await _headers,
          body: {
            'receiverId': member.id,
            'introductoryMessage': intro.isEmpty ? null : intro,
          },
        ),
        accepted: const {201},
      );
      await _searchMembers();
      await _load();
      if (mounted) _toast('Connection request sent to ${member.name}.');
    } on AuthFailure catch (failure) {
      if (mounted) _toast(failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [_connected, _incoming, _outgoing][_tab];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _discover ? 'Discover people' : 'Connections',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _discover
                        ? 'Find students and alumni, then start a connection.'
                        : 'Requests and people you know.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _busy
                  ? null
                  : _discover
                  ? _searchMembers
                  : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Discover'),
              selected: _discover,
              onSelected: _busy ? null : (_) => _showDiscover(true),
            ),
            ChoiceChip(
              label: const Text('Connections'),
              selected: !_discover,
              onSelected: _busy ? null : (_) => _showDiscover(false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_discover) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tabButton('Connected', 0, _connected.length),
              _tabButton('Received', 1, _incoming.length),
              _tabButton('Sent', 2, _outgoing.length),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Filter this list by name',
              suffixIcon: IconButton(
                onPressed: () {
                  _search.clear();
                  _load();
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discoverySearch,
                  onSubmitted: (_) => _searchMembers(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search students and alumni',
                    suffixIcon: IconButton(
                      onPressed: _searchMembers,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _searchMembers,
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$_total people',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_error != null) _errorPanel(),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          const SizedBox.shrink()
        else if (_discover)
          _memberList()
        else if (rows.isEmpty)
          _emptyPanel()
        else
          ...rows.map(_connectionTile),
      ],
    );
  }

  Widget _tabButton(String label, int index, int count) => ChoiceChip(
    label: Text('$label  $count'),
    selected: _tab == index,
    onSelected: _busy ? null : (_) => setState(() => _tab = index),
  );

  Widget _connectionTile(_ConnectionRow row) {
    final incoming = _tab == 1;
    final outgoing = _tab == 2;
    final subtitle = row.connection.intro.isNotEmpty
        ? '“${row.connection.intro}”'
        : (incoming
              ? 'Would like to connect with you.'
              : outgoing
              ? 'Connection request sent.'
              : 'Connected with you.');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final identity = Expanded(
              child: Row(
                children: [
                  _avatar(row.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: incoming
                  ? [
                      FilledButton(
                        onPressed: _busy ? null : () => _act(row, 'accept'),
                        child: const Text('Accept'),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _act(row, 'reject'),
                        child: const Text('Decline'),
                      ),
                    ]
                  : outgoing
                  ? [
                      OutlinedButton(
                        onPressed: _busy ? null : () => _act(row, 'cancel'),
                        child: const Text('Cancel request'),
                      ),
                    ]
                  : [
                      OutlinedButton.icon(
                        onPressed:
                            widget.onOpenMessages ??
                            () => Navigator.pushNamed(context, '/chat'),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message'),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Connection actions',
                        onSelected: (value) => _confirmRemove(row),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove connection'),
                          ),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.more_horiz),
                        ),
                      ),
                    ],
            );
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [identity, const SizedBox(height: 12), actions],
                  )
                : Row(children: [identity, const SizedBox(width: 12), actions]);
          },
        ),
      ),
    );
  }

  Future<void> _confirmRemove(_ConnectionRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove connection?'),
        content: Text('${row.name} will no longer appear in your connections.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep connection'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _act(row, 'remove');
  }

  Widget _memberList() {
    if (_members.isEmpty) {
      return _emptyPanel(
        message: 'No people matched that search. Try another name.',
      );
    }
    return Column(
      children: _members
          .map(
            (member) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _avatar(member.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            member.headline,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _memberAction(member),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _memberAction(_Member member) {
    final connection = member.connection;
    if (connection == null) {
      return FilledButton.icon(
        onPressed: _busy ? null : () => _send(member),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Connect'),
      );
    }
    if (connection.status == 'ACCEPTED') {
      return const Chip(
        label: Text('Connected'),
        avatar: Icon(Icons.check, size: 16),
      );
    }
    if (connection.status == 'PENDING') {
      return Chip(
        label: Text(
          connection.outgoing ? 'Request sent' : 'Respond to request',
        ),
      );
    }
    return FilledButton.icon(
      onPressed: _busy ? null : () => _send(member),
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Connect'),
    );
  }

  Widget _avatar(String name) => CircleAvatar(
    radius: 22,
    child: Text(
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
    ),
  );

  Widget _emptyPanel({String? message}) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          children: [
            Icon(
              _discover ? Icons.person_search_outlined : Icons.people_outline,
              size: 38,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message ??
                  switch (_tab) {
                    0 => 'Your accepted connections will appear here.',
                    1 => 'You’re all caught up. New requests will appear here.',
                    _ => 'Connection requests you send will appear here.',
                  },
              textAlign: TextAlign.center,
            ),
            if (!_discover && _tab == 0) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _discover = true);
                  _searchMembers();
                },
                icon: const Icon(Icons.person_search_outlined),
                label: const Text('Find people'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _errorPanel() => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: Text(_error!)),
          TextButton(
            onPressed: _discover ? _searchMembers : _load,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _ConnectionRow {
  const _ConnectionRow(this.connection, this.otherUserId, this.name);
  final _Connection connection;
  final int? otherUserId;
  final String name;
  factory _ConnectionRow.fromJson(Map<String, dynamic> json) => _ConnectionRow(
    _Connection.fromJson(json['connection'] as Map<String, dynamic>),
    (json['otherUserId'] as num?)?.toInt(),
    json['fullName'] as String? ?? 'Unavailable member',
  );
}

class _Connection {
  const _Connection(this.id, this.status, this.intro);
  final int id;
  final String status;
  final String intro;
  factory _Connection.fromJson(Map<String, dynamic> json) => _Connection(
    (json['id'] as num).toInt(),
    json['status'] as String? ?? '',
    json['introductoryMessage'] as String? ?? '',
  );
}

class _Member {
  const _Member(this.id, this.name, this.headline, this.connection);
  final int id;
  final String name;
  final String headline;
  final _MemberConnection? connection;
  factory _Member.fromJson(Map<String, dynamic> json) {
    final department = json['department'] as Map<String, dynamic>?;
    final programme = json['programme'] as Map<String, dynamic>?;
    final role = json['platformRole'] as String? ?? 'STUDENT';
    final details = json['details'] as Map<String, dynamic>?;
    final student = details?['student'] as Map<String, dynamic>?;
    final alumni = details?['alumni'] as Map<String, dynamic>?;
    final year = student?['yearOfStudy'];
    final detailLabel = role == 'ALUMNI'
        ? (alumni?['currentJobTitle'] ?? alumni?['company'])
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
    return _Member(
      (json['userId'] as num).toInt(),
      json['fullName'] as String? ?? 'UniConnect member',
      headline,
      connectionJson == null
          ? null
          : _MemberConnection.fromJson(connectionJson),
    );
  }
}

class _MemberConnection {
  const _MemberConnection(this.status, this.outgoing);
  final String status;
  final bool outgoing;
  factory _MemberConnection.fromJson(Map<String, dynamic> json) =>
      _MemberConnection(
        json['status'] as String? ?? '',
        json['outgoing'] as bool? ?? false,
      );
}
