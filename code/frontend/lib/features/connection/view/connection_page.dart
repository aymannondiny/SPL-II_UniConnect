import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

import '../data/connection_repository.dart';
import '../model/connection_models.dart';
import '../controller/connection_controller.dart';
import 'widgets/connection_toolbar.dart';
import 'widgets/connection_tile.dart';
import 'widgets/member_tile.dart';
import 'member_profile_page.dart';

import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';

/// Connections and member discovery, backed by the authenticated REST APIs.
class ConnectionPage extends StatefulWidget {
  const ConnectionPage({
    required this.session,
    this.initialDiscovery = false,
    this.onOpenMessages,
    this.repository,
    this.active = true,
    super.key,
  });
  final SessionController session;
  final ConnectionRepository? repository;
  final bool active;
  final bool initialDiscovery;
  final ValueChanged<ChatConnection>? onOpenMessages;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  late final ApiClient _client;
  late final ConnectionRepository _repository;
  late final ConnectionController _controller;
  bool get _loading => _controller.loading;
  bool get _loadingMore => _controller.loadingMore;
  String? get _error => _controller.error;
  List<ConnectionRow> get _connected => _controller.connected;
  List<ConnectionRow> get _incoming => _controller.incoming;
  List<ConnectionRow> get _outgoing => _controller.outgoing;
  List<MemberProfile> get _members => _controller.members;
  int get _total => _controller.total;
  final _search = TextEditingController();
  final _discoverySearch = TextEditingController();
  int _tab = 0;
  bool _discover = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _repository =
        widget.repository ?? ConnectionRepository(_client, widget.session);
    _controller = ConnectionController(_repository)..addListener(_changed);
    _discover = widget.initialDiscovery;
    _discover ? _searchMembers() : _load();
  }

  @override
  void didUpdateWidget(covariant ConnectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _discover ? _searchMembers() : _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _discoverySearch.dispose();
    _controller.removeListener(_changed);
    _controller.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _load() => _controller.load(_search.text.trim());
  Future<void> _searchMembers({bool more = false}) =>
      _controller.search(_discoverySearch.text.trim(), more: more);
  void _changed() {
    if (mounted) setState(() {});
  }

  void _showDiscover(bool discover) {
    if (_discover == discover || _busy) return;
    _controller.invalidate();
    setState(() {
      _discover = discover;
    });
    if (discover) {
      _searchMembers();
    } else {
      _load();
    }
  }

  Future<void> _act(ConnectionRow row, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repository.act(row.connection.id, action);
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

  Future<void> _send(MemberProfile member) async {
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
      await _repository.send(member.id, intro);
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
    final rows = [_connected, _incoming, _outgoing][_tab];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConnectionToolbar(
          discover: _discover,
          busy: _busy,
          loading: _loading,
          repository: _repository,
          search: _search,
          discoverySearch: _discoverySearch,
          total: _total,
          counts: [_connected.length, _incoming.length, _outgoing.length],
          tab: _tab,
          onTab: (index) => setState(() => _tab = index),
          onMode: _showDiscover,
          onConnectionSearch: _load,
          onDiscoverSearch: _searchMembers,
          onFilters: (filters) {
            _controller.filters = filters;
            _searchMembers();
          },
        ),
        if (_error != null) _errorPanel(),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null && (!_discover || _members.isEmpty))
          const SizedBox.shrink()
        else if (_discover)
          _memberList()
        else if (rows.isEmpty)
          _emptyPanel()
        else
          ...rows.map(_connectionTile),
        if (_discover && !_loading && _members.length < _total)
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadingMore ? null : () => _searchMembers(more: true),
              icon: const Icon(Icons.expand_more),
              label: Text(_loadingMore ? 'Loading…' : 'Load more people'),
            ),
          ),
      ],
    );
  }

  Widget _connectionTile(ConnectionRow row) => ConnectionTile(
    row: row,
    tab: _tab,
    busy: _busy,
    onAction: (action) => _act(row, action),
    onRemove: () => _confirmRemove(row),
    onMessage: () => _openMessages(row.otherUserId!, row.name),
  );

  Future<void> _confirmRemove(ConnectionRow row) async {
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
        message: 'No people matched these filters. Try a broader search.',
      );
    }
    return Column(
      children: [
        for (final member in _members)
          MemberTile(
            member: member,
            onProfile: () => _openMember(member),
            action: _memberAction(member),
          ),
      ],
    );
  }

  void _openMessages(int id, String name) {
    final recipient = ChatConnection(userId: id, fullName: name);
    if (widget.onOpenMessages != null) {
      widget.onOpenMessages!(recipient);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatPage(
            sessionController: widget.session,
            initialRecipient: recipient,
          ),
        ),
      );
    }
  }

  Future<void> _openMember(MemberProfile member) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberProfilePage(
          repository: _repository,
          memberId: member.id,
          onConnect: _busy ? null : _send,
          onMessage: (profile) {
            Navigator.of(context).pop();
            _openMessages(profile.id, profile.name);
          },
        ),
      ),
    );
    if (mounted) await _searchMembers();
  }

  Widget _memberAction(MemberProfile member) {
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
