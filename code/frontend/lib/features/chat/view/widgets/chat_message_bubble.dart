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
    final foreground = own ? colors.onPrimary : colors.onSurface;
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
              if (value == 'self') onDeleteSelf();
              if (value == 'everyone') onDeleteEveryone?.call();
            },
            itemBuilder: (_) => [
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
                    style: TextStyle(
                      color: message.deletedForEveryone
                          ? colors.onSurfaceVariant
                          : foreground,
                      fontSize: 14.5,
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
                        style: TextStyle(
                          color: foreground.withValues(alpha: .72),
                          fontSize: 11.5,
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
