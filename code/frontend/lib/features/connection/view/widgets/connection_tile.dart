import 'package:flutter/material.dart';

import '../../model/connection_models.dart';

/// Responsive identity and actions for a single connection or request.
class ConnectionTile extends StatelessWidget {
  const ConnectionTile({
    required this.row,
    required this.tab,
    required this.busy,
    required this.onAction,
    required this.onRemove,
    required this.onMessage,
    super.key,
  });
  final ConnectionRow row;
  final int tab;
  final bool busy;
  final ValueChanged<String> onAction;
  final VoidCallback onRemove;
  final VoidCallback onMessage;
  @override
  Widget build(BuildContext context) {
    final incoming = tab == 1;
    final outgoing = tab == 2;
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
            final identity = Row(
              children: [
                CircleAvatar(
                  child: Text(
                    row.name.trim().isEmpty
                        ? '?'
                        : row.name.characters.first.toUpperCase(),
                  ),
                ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: incoming
                  ? [
                      FilledButton(
                        onPressed: busy ? null : () => onAction('accept'),
                        child: const Text('Accept'),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => onAction('reject'),
                        child: const Text('Decline'),
                      ),
                    ]
                  : outgoing
                  ? [
                      OutlinedButton(
                        onPressed: busy ? null : () => onAction('cancel'),
                        child: const Text('Cancel request'),
                      ),
                    ]
                  : [
                      OutlinedButton.icon(
                        onPressed: row.otherUserId == null
                            ? null
                            : () => onMessage(),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message'),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Connection actions',
                        onSelected: (value) => onRemove(),
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
                : Row(
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 12),
                      actions,
                    ],
                  );
          },
        ),
      ),
    );
  }
}
