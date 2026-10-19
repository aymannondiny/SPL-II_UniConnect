import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/profile/data/account_profile_repository.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({
    required this.account,
    required this.session,
    required this.repository,
    super.key,
  });
  final CurrentAccount account;
  final SessionController session;
  final AccountProfileRepository repository;

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.account.fullName);
  late String _savedName = widget.account.fullName;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.updateName(_name.text.trim());
      widget.session.updateName(updated.fullName);
      if (!mounted) return;
      setState(() {
        _savedName = updated.fullName;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account details are saved.')),
      );
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = failure.message;
        _saving = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to update your account details. Please retry.';
        _saving = false;
      });
    }
  }

  String get _initials {
    final parts = widget.account.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changed = _name.text.trim() != _savedName;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My profile',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your administrator account details.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _saving || !changed ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_saving ? 'Saving…' : 'Save changes'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 18,
                runSpacing: 16,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: .14,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(
                      _initials,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.fullName,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.account.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const _StatusChip(
                              label: 'System administrator',
                              icon: Icons.shield_outlined,
                            ),
                            const _StatusChip(
                              label: 'Verified IUT email',
                              icon: Icons.verified_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final details = SectionCard(
                title: 'Account details',
                subtitle: 'Your display name appears throughout UniConnect.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) return 'Enter your name.';
                        if (name.length > 100) {
                          return 'Use no more than 100 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    _ReadOnlyDetail(
                      label: 'Email',
                      value: widget.account.email,
                      icon: Icons.mail_outline,
                    ),
                    const SizedBox(height: 12),
                    _ReadOnlyDetail(
                      label: 'Account ID',
                      value: widget.account.userId.toString(),
                      icon: Icons.badge_outlined,
                    ),
                  ],
                ),
              );
              final access = SectionCard(
                title: 'Access and security',
                subtitle: 'Administrator access is assigned by UniConnect.',
                child: Column(
                  children: [
                    _AccessRow(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Account type',
                      value: 'System administrator',
                    ),
                    const Divider(height: 24),
                    _AccessRow(
                      icon: Icons.verified_user_outlined,
                      title: 'Account status',
                      value: widget.account.accountStatus == 'ACTIVE'
                          ? 'Active'
                          : widget.account.accountStatus,
                    ),
                    const Divider(height: 24),
                    Text(
                      'The administrator role cannot be changed from your profile.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
              return constraints.maxWidth >= 800
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 20),
                        Expanded(child: access),
                      ],
                    )
                  : Column(
                      children: [details, const SizedBox(height: 20), access],
                    );
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyDetail extends StatelessWidget {
  const _ReadOnlyDetail({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 19, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        Icon(
          Icons.lock_outline,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(value, style: theme.textTheme.labelLarge),
      ],
    );
  }
}
