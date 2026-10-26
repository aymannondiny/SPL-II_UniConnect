import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/features/chat/view/widgets/chat_message_bubble.dart';

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? AppTheme.dark() : AppTheme.light();
    testWidgets(
      'deleted outgoing message remains readable in ${theme.brightness}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: ChatMessageBubble(
                message: ChatMessage(
                  id: 1,
                  conversationId: 1,
                  senderId: 1,
                  clientMessageId: 'deleted-message',
                  content: null,
                  sentAt: DateTime(2026, 10, 26, 10, 30),
                  deliveredAt: null,
                  readAt: null,
                  deletedForEveryoneAt: DateTime(2026, 10, 26, 10, 31),
                ),
                own: true,
                onDeleteSelf: () {},
                onDeleteEveryone: null,
              ),
            ),
          ),
        );

        final timestamp = tester.widget<Text>(find.text('10:30 AM'));
        final foreground = timestamp.style!.color!;
        final background = theme.colorScheme.surfaceContainerHighest;
        final displayed = Color.alphaBlend(foreground, background);
        final a = displayed.computeLuminance();
        final b = background.computeLuminance();
        final contrast =
            (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
        expect(contrast, greaterThanOrEqualTo(4.5));
        expect(timestamp.style!.fontFamily, AppTheme.fontFamily);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
