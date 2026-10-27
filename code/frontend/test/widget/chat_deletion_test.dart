import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';

import '../../tool/support/fake_chat_repository.dart';
import '../../tool/support/fake_session_repository.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      AppTheme.fontFamily,
    )..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final fails in [false, true]) {
      testWidgets(
        'chat deletion confirmation and result at $size, failure=$fails',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final session = SessionController(FakeSessionRepository());
          addTearDown(session.dispose);
          await session.login('member@iut-dhaka.edu', 'password');
          final client = ApiClient();
          addTearDown(client.close);
          final repository = _DeletionRepository(client, fails: fails);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              debugShowCheckedModeBanner: false,
              home: ChatPage(
                sessionController: session,
                repository: repository,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (!fails) {
            await expectLater(
              find.byType(ChatPage),
              matchesGoldenFile(
                'goldens/chat_delete_${size.width.toInt()}_inbox.png',
              ),
            );
          }
          await tester.tap(find.byTooltip('Chat options for Nafisa Rahman'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete chat for me'));
          await tester.pumpAndSettle();
          expect(find.text('Delete chat for me?'), findsOneWidget);
          if (!fails) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/chat_delete_${size.width.toInt()}_dialog.png',
              ),
            );
          }
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(repository.attempts, 0);
          await tester.tap(find.byTooltip('Chat options for Nafisa Rahman'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete chat for me'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete chat'));
          await tester.pumpAndSettle();
          expect(repository.attempts, 1);
          expect(repository.conversationDeleted, !fails);
          expect(
            find.text('Nafisa Rahman'),
            fails ? findsOneWidget : findsNothing,
          );
          if (fails) {
            expect(find.text('Deletion failed. Try again.'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await session.logout();
        },
      );
    }
  }
}

class _DeletionRepository extends FakeChatRepository {
  _DeletionRepository(super.client, {required this.fails});
  final bool fails;
  int attempts = 0;

  @override
  Future<void> deleteConversation(String token, int conversationId) async {
    attempts++;
    if (fails) throw const ChatFailure('Deletion failed. Try again.');
    await super.deleteConversation(token, conversationId);
  }
}
