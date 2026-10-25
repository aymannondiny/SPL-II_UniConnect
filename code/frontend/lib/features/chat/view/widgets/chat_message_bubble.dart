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
    final bubble = own ? colors.primary : colors.surfaceContainerHighest;
    final foreground = message.deletedForEveryone
        ? colors.onSurfaceVariant
        : own
        ? colors.onPrimary
        : colors.onSurface;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(MediaQuery.sizeOf(context).width * .7, 420),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
              const PopupMenuItem(value: 'self', child: Text('Delete for me')),
              if (onDeleteEveryone != null)
                const PopupMenuItem(
                  value: 'everyone',
                  child: Text('Delete for everyone'),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.deletedForEveryone
                    ? colors.surfaceContainerHighest
                    : bubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(own ? 6 : 18),
                  bottomRight: Radius.circular(own ? 18 : 6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content ?? 'This message was deleted.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: message.deletedForEveryone
                          ? colors.onSurfaceVariant
                          : foreground,
                      fontStyle: message.deletedForEveryone
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chatClockTime(message.sentAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: message.deletedForEveryone
                              ? foreground
                              : foreground.withValues(alpha: .72),
                        ),
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
                              ? colors.tertiary
                              : foreground.withValues(alpha: .72),
                        ),
                      ],
                    ],
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
