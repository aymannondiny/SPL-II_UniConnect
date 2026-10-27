import 'package:uniconnect/features/reporting/view/report_content_button.dart';
import 'package:flutter/material.dart';

import 'dart:math' as math;

import '../../model/chat_models.dart';
import '../chat_time_format.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.own,
    required this.onDeleteSelf,
    required this.onDeleteEveryone,
  });

  final ChatMessage message;
  final bool own;
  final VoidCallback onDeleteSelf;
  final VoidCallback? onDeleteEveryone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bubble = own ? colors.surfaceContainerHighest : colors.surface;
    final foreground = message.deletedForEveryone
        ? colors.onSurfaceVariant
        : colors.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: own ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(constraints.maxWidth * .88, 480),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: PopupMenuButton<String>(
              tooltip: 'Message actions',
              onSelected: (value) {
                if (value == 'report') {
                  ReportContentButton.open(
                    context,
                    targetType: 'CHAT_MESSAGE',
                    targetId: message.id,
                  );
                }
                if (value == 'self') onDeleteSelf();
                if (value == 'everyone') onDeleteEveryone?.call();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report message'),
                ),
                const PopupMenuItem(
                  value: 'self',
                  child: Text('Delete for me'),
                ),
                if (onDeleteEveryone != null)
                  const PopupMenuItem(
                    value: 'everyone',
                    child: Text('Delete for everyone'),
                  ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: own
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                      left: const Radius.circular(10),
                      right: Radius.circular(own ? 4 : 10),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: message.deletedForEveryone
                            ? colors.surfaceContainerHighest
                            : bubble,
                        borderRadius: BorderRadius.horizontal(
                          left: const Radius.circular(10),
                          right: Radius.circular(own ? 4 : 10),
                        ),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: .65),
                        ),
                      ),
                      foregroundDecoration: own && !message.deletedForEveryone
                          ? BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: colors.primary,
                                  width: 3,
                                ),
                              ),
                            )
                          : null,
                      child: Text(
                        message.content ?? 'This message was deleted.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontStyle: message.deletedForEveryone
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chatClockTime(message.sentAt.toLocal()),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        if (own && !message.deletedForEveryone) ...[
                          const SizedBox(width: 5),
                          Icon(
                            message.readAt != null
                                ? Icons.done_all_rounded
                                : message.deliveredAt != null
                                ? Icons.done_all_rounded
                                : Icons.check_rounded,
                            size: 14,
                            color: message.readAt != null
                                ? colors.primary
                                : colors.onSurfaceVariant,
                            semanticLabel: message.readAt != null
                                ? 'Read'
                                : message.deliveredAt != null
                                ? 'Delivered'
                                : 'Sent',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
