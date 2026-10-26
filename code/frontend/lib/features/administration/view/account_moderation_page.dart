import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/administration/data/account_moderation_repository.dart';
import 'package:uniconnect/features/administration/model/moderated_account.dart';
import 'package:uniconnect/features/administration/view/account_details_dialog.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

class AccountModerationPage extends StatefulWidget {
  const AccountModerationPage({required this.repository, super.key});
  final AccountModerationRepository repository;

  @override
  State<AccountModerationPage> createState() => _AccountModerationPageState();
}

class _AccountModerationPageState extends State<AccountModerationPage> {
  final _search = TextEditingController();
  String _role = '';
  String _status = '';
  List<ModeratedAccount> _items = [];
  int _total = 0;
  int _page = 0;
  bool _loading = false;
  bool _retryMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _retryMore = more;
    final page = more ? _page + 1 : 0;
    try {
      final result = await widget.repository.search(
        page: page,
        search: _search.text,
        role: _role,
        status: _status,
      );
      if (mounted) {
        setState(() {
          _items = more ? [..._items, ...result.items] : result.items;
          _total = result.total;
          _page = page;
        });
      }
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(int id) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          AccountDetailsDialog(repository: widget.repository, id: id),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Account moderation',
    subtitle: 'Search members, review audit history and manage account access.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          enabled: !_loading,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            labelText: 'Search name or email',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'Search accounts',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _role,
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() => _role = value!);
                        _load();
                      },
                items: [
                  const DropdownMenuItem(value: '', child: Text('All roles')),
                  for (final role in ['STUDENT', 'ALUMNI', 'SYSTEM_ADMIN'])
                    DropdownMenuItem(
                      value: role,
                      child: Text(role.replaceAll('_', ' ')),
                    ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _status,
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() => _status = value!);
                        _load();
                      },
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All statuses'),
                  ),
                  for (final status in [
                    'ACTIVE',
                    'SUSPENDED',
                    'PENDING_VERIFICATION',
                  ])
                    DropdownMenuItem(
                      value: status,
                      child: Text(status.replaceAll('_', ' ')),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _loading ? null : () => _load(more: _retryMore),
            child: const Text('Retry'),
          ),
        ] else if (!_loading && _items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No accounts match these filters.'),
          ),
        for (final account in _items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(account.name),
            subtitle: Text(
              '${account.email}\n${account.role} · ${account.status}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(account.id),
          ),
        if (_error == null && _items.length < _total)
          TextButton(
            onPressed: _loading ? null : () => _load(more: true),
            child: Text('Load more (${_items.length} of $_total)'),
          ),
      ],
    ),
  );
}
