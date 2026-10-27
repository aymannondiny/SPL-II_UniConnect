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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bubble = own
        ? dark
              ? colors.surfaceContainerHighest
              : colors.primary
        : colors.surface;
    final foreground = message.deletedForEveryone
        ? colors.onSurfaceVariant
        : own
        ? dark
              ? colors.onSurface
              : colors.onPrimary
        : colors.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: own ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(constraints.maxWidth * .88, 480),
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
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  own ? 12 : 19,
                  9,
                  own ? 19 : 12,
                  7,
                ),
                decoration: ShapeDecoration(
                  color: message.deletedForEveryone
                      ? colors.surfaceContainerHighest
                      : bubble,
                  shape: _ChatBubbleShape(own: own),
                  shadows: [
                    BoxShadow(
                      color: colors.onSurface.withValues(alpha: .08),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 3,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chatClockTime(message.sentAt.toLocal()),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
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
                                ? dark
                                      ? colors.primary
                                      : foreground
                                : foreground.withValues(alpha: .72),
                            semanticLabel: message.readAt != null
                                ? 'Read'
                                : message.deliveredAt != null
                                ? 'Delivered'
                                : 'Sent',
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
      ),
    );
  }
}

/// Keeps the tail inside the bubble's layout bounds and tappable area.
class _ChatBubbleShape extends ShapeBorder {
  const _ChatBubbleShape({required this.own});

  final bool own;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body = Rect.fromLTRB(
      rect.left + (own ? 0 : 7),
      rect.top,
      rect.right - (own ? 7 : 0),
      rect.bottom,
    );
    final path = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          body,
          topLeft: Radius.circular(own ? 9 : 0),
          topRight: Radius.circular(own ? 0 : 9),
          bottomLeft: const Radius.circular(9),
          bottomRight: const Radius.circular(9),
        ),
      );
    path.addPolygon(
      own
          ? [body.topRight, rect.topRight, body.topRight + const Offset(0, 10)]
          : [rect.topLeft, body.topLeft, body.topLeft + const Offset(0, 10)],
      true,
    );
    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
