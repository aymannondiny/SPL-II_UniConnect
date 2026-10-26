import 'package:flutter/material.dart';
import 'package:uniconnect/features/administration/data/account_moderation_repository.dart';
import 'package:uniconnect/features/administration/model/moderated_account.dart';
import 'package:uniconnect/features/administration/view/account_transition_dialog.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

class AccountDetailsDialog extends StatefulWidget {
  const AccountDetailsDialog({
    required this.repository,
    required this.id,
    super.key,
  });
  final AccountModerationRepository repository;
  final int id;

  @override
  State<AccountDetailsDialog> createState() => _AccountDetailsDialogState();
}

class _AccountDetailsDialogState extends State<AccountDetailsDialog> {
  ModeratedAccount? _account;
  List<Map<String, dynamic>> _audit = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _run(() async {
      final account = await widget.repository.detail(widget.id);
      final audit = await widget.repository.audit(widget.id);
      if (mounted) {
        setState(() {
          _account = account;
          _audit = audit;
        });
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _transition(bool suspend) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) =>
          AccountTransitionDialog(name: _account!.name, suspend: suspend),
    );
    if (!mounted || reason == null) return;
    await _run(
      () => widget.repository.transition(
        widget.id,
        suspend: suspend,
        reason: reason,
      ),
    );
    if (mounted && _error == null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return AlertDialog(
      title: Text(account?.name ?? 'Account #${widget.id}'),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Retry'),
                ),
              ],
              if (account != null) ...[
                Text(account.email),
                Text('${account.role} · ${account.status}'),
                const SizedBox(height: 20),
                Text(
                  'Moderation history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_audit.isEmpty) const Text('No account actions recorded.'),
                for (final entry in _audit)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${entry['actionType']} · Action #${entry['actionId']}',
                    ),
                    subtitle: Text(
                      '${entry['reason']}\n${entry['occurredAt']} · Actor ${entry['actorId']}${entry['reversedAt'] == null ? '' : '\nReversed: ${entry['reversedAt']}'}',
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (account?.canSuspend == true)
          FilledButton(
            onPressed: _busy ? null : () => _transition(true),
            child: const Text('Suspend'),
          ),
        if (account?.canRestore == true)
          FilledButton(
            onPressed: _busy ? null : () => _transition(false),
            child: const Text('Restore'),
          ),
      ],
    );
  }
}
