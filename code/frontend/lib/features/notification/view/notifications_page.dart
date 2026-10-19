import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/notification/data/notification_repository.dart';
import 'package:uniconnect/features/notification/model/app_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    required this.repository,
    required this.onOpenFeature,
    required this.active,
    super.key,
  });

  final NotificationRepository repository;
  final ValueChanged<String> onOpenFeature;
  final bool active;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  List<AppNotification> _items = const [];
  bool _loading = true;
  bool _markingAll = false;
  bool _fetching = false;
  final Set<int> _deleting = {};
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    if (widget.active) _startPolling();
  }

  @override
  void didUpdateWidget(covariant NotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      unawaited(_load());
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active) {
      unawaited(_load(showLoading: false));
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_load(showLoading: false)),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (_fetching) return;
    _fetching = true;
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await widget.repository.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (showLoading || _items.isEmpty) _error = failure.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (showLoading || _items.isEmpty) {
          _error = 'Unable to load notifications. Please retry.';
        }
      });
    } finally {
      _fetching = false;
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || _items.every((item) => item.isRead)) return;
    setState(() => _markingAll = true);
    try {
      await widget.repository.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _items.map((item) => item.markRead()).toList();
        _markingAll = false;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() => _markingAll = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    } on Object {
      if (!mounted) return;
      setState(() => _markingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update notifications.')),
      );
    }
  }

  Future<void> _delete(AppNotification item) async {
    if (!_deleting.add(item.id)) return;
    setState(() {});
    try {
      await widget.repository.delete(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((current) => current.id != item.id).toList();
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete this notification.')),
      );
    } finally {
      _deleting.remove(item.id);
      if (mounted) setState(() {});
    }
  }

  String _destination(AppNotification item) => switch (item.referenceType) {
    'CONNECTION' => 'Connections',
    'CLUB' => 'Clubs & events',
    'CONVERSATION' => 'Messages',
    'USER' => 'My profile',
    _ => 'Notifications',
  };

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      try {
        await widget.repository.markRead(item.id);
        if (mounted) {
          setState(() {
            _items = [
              for (final current in _items)
                if (current.id == item.id) current.markRead() else current,
            ];
          });
        }
      } on Object {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification could not be marked as read.'),
            ),
          );
        }
      }
    }
    if (mounted) widget.onOpenFeature(_destination(item));
  }

  String _timeLabel(DateTime time) {
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours} hr ago';
    if (elapsed.inDays < 7) return '${elapsed.inDays} days ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = _items.where((item) => !item.isRead).length;
    return Column(
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
                  'Notifications',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _loading
                      ? 'Loading your notifications…'
                      : _error != null
                      ? 'Unable to check for new notifications right now.'
                      : unread == 0
                      ? 'You are all caught up.'
                      : 'New requests, messages and campus updates appear here automatically.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: _markingAll || unread == 0 ? null : _markAllRead,
              icon: _markingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all as read'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionCard(
          title: 'Recent activity',
          subtitle: _loading
              ? 'Loading your latest notifications…'
              : _error != null
              ? 'Notifications unavailable'
              : '${_items.length} notifications',
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
              ? _MessageState(
                  icon: Icons.cloud_off_outlined,
                  message: _error!,
                  action: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                )
              : _items.isEmpty
              ? const _MessageState(
                  icon: Icons.notifications_none,
                  message: 'Your notifications will appear here.',
                )
              : Column(
                  children: [
                    for (final item in _items) ...[
                      _NotificationRow(
                        item: item,
                        timeLabel: _timeLabel(item.createdAt),
                        onTap: () => _open(item),
                        onDelete: () => _delete(item),
                        deleting: _deleting.contains(item.id),
                      ),
                      if (item != _items.last)
                        Divider(
                          height: 1,
                          color: theme.dividerColor.withValues(alpha: .2),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.timeLabel,
    required this.onTap,
    required this.onDelete,
    required this.deleting,
  });
  final AppNotification item;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool deleting;

  IconData get _icon => switch (item.type) {
    'CONNECTION_REQUESTED' => Icons.person_add_alt_1_outlined,
    'CONNECTION_ACCEPTED' => Icons.people_alt_outlined,
    'NEW_MESSAGE' => Icons.mark_chat_unread_outlined,
    'CLUB_ROLE_GRANTED' || 'CLUB_ROLE_REVOKED' => Icons.groups_2_outlined,
    'PUBLISHING_SUSPENDED' || 'PUBLISHING_RESTORED' => Icons.campaign_outlined,
    'ACCOUNT_SUSPENDED' || 'ACCOUNT_REACTIVATED' =>
      Icons.admin_panel_settings_outlined,
    _ => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: item.isRead
          ? Colors.transparent
          : theme.colorScheme.primary.withValues(alpha: .055),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: item.isRead
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: .12,
                      ),
                      foregroundColor: theme.colorScheme.primary,
                      child: Icon(_icon, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(item.message, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            timeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Delete notification',
              onPressed: deleting ? null : onDelete,
              icon: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 25),
    child: Column(
      children: [
        Icon(
          icon,
          size: 38,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 8), action!],
      ],
    ),
  );
}
