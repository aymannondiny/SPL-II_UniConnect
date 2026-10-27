import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_chat_repository.dart';
import '../../tool/support/fake_profile_repository.dart';
import '../../tool/support/fake_session_repository.dart';

// Profile coverage and rendered evidence for the responsive messaging layout.
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

  for (final profileKind in [
    'STUDENT',
    'ALUMNI',
    'ALUMNI_EMPTY',
    'SYSTEM_ADMIN',
    'CLUB_ADMINISTRATOR',
    'REPRESENTATIVE',
  ]) {
    final club = ['CLUB_ADMINISTRATOR', 'REPRESENTATIVE'].contains(profileKind);
    final empty = profileKind == 'ALUMNI_EMPTY';
    final role = club ? 'STUDENT' : (empty ? 'ALUMNI' : profileKind);
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(900, 700),
      const Size(1440, 900),
      const Size(1536, 864),
      const Size(1920, 1080),
    ]) {
      testWidgets('message profile audit $profileKind $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = SessionController(FakeSessionRepository());
        await session.login('member@iut-dhaka.edu', 'password');
        session.account = CurrentAccount(
          userId: 1,
          fullName: 'Test Member',
          email: 'member@iut-dhaka.edu',
          platformRole: role,
        );
        final campus = CampusFixtureApi(
          role: role,
          clubRole: club ? profileKind : null,
        );
        if (club) {
          campus.activeContext = {
            'contextType': 'CLUB',
            'assignmentId': 10,
            'clubId': 1,
            'clubName': 'Programming Club',
            'clubRole': profileKind,
          };
        }
        final client = ApiClient(client: campus.client);
        final repository = empty
            ? _EmptyChatRepository(client)
            : FakeChatRepository(client);
        final profile = FakeProfileRepository()
          ..profile = FakeProfileRepository.fixture(role: role);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: SessionScope(
              controller: session,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark(),
                home: AuthenticatedWorkspace(
                  repository: profile,
                  apiClient: client,
                  clubRepository: ClubRepository(client, session),
                  chatRepository: repository,
                  initialFeature: 'Messages',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final name = '$profileKind-${size.width.toInt()}';
        if (club || role == 'SYSTEM_ADMIN') {
          // Management contexts intentionally exclude personal messaging.
          expect(find.byType(ChatPage), findsNothing);
          expect(find.text('Messages').hitTestable(), findsNothing);
          expect(tester.takeException(), isNull);
          await _capture(tester, boundary, '$name-access');
          await tester.pumpWidget(const SizedBox());
          session.dispose();
          client.close();
          return;
        }
        expect(find.byType(ChatPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          find.text('Good conversations start here'),
          size.width >= 900 ? findsOneWidget : findsNothing,
        );
        // Messages fills the workspace instead of centering a capped panel.
        final panel = tester.getRect(find.byType(ChatPage));
        final inbox = tester.getRect(
          find
              .descendant(
                of: find.byType(ChatPage),
                matching: find.text('Messages'),
              )
              .first,
        );
        expect(inbox.top - panel.top, lessThan(60));
        await _capture(tester, boundary, '$name-inbox');
        if (empty) {
          expect(find.text('Your inbox is quiet'), findsOneWidget);
          await tester.tap(find.byTooltip('Start a conversation'));
          await tester.pumpAndSettle();
          expect(
            find.text(
              'You already have conversations with all your accepted connections.',
            ),
            findsOneWidget,
          );
          await _capture(tester, boundary, '$name-no-connections');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          session.dispose();
          client.close();
          return;
        }
        await tester.tap(find.text('Nafisa Rahman'));
        await tester.pumpAndSettle();
        expect(repository.openedConversation, 81);
        final composer = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Write a message',
        );
        expect(composer, findsOneWidget);
        await tester.enterText(composer, 'Profile audit message');
        await tester.pump();
        await tester.tap(find.byTooltip('Send message'));
        await tester.pumpAndSettle();
        expect(repository.sentRecipient, 2);
        expect(find.text('Profile audit message'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, boundary, '$name-thread');
        // Desktop keeps the inbox beside the selected thread.
        expect(
          find.byTooltip('Back to inbox'),
          size.width < 900 ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Search conversations'),
          size.width >= 900 ? findsOneWidget : findsNothing,
        );
        final composerRect = tester.getRect(composer);
        expect(panel.bottom - composerRect.bottom, lessThan(60));
        if (size.width == 390) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          await _capture(tester, boundary, '$name-keyboard');
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
        }
        await tester.pumpWidget(const SizedBox());
        session.dispose();
        client.close();
      });
    }
  }
}

class _EmptyChatRepository extends FakeChatRepository {
  _EmptyChatRepository(super.client);

  @override
  Future<List<ChatConversation>> conversations(String token) async => [];

  @override
  Future<List<ChatConnection>> acceptedConnections(String token) async => [];
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final render =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/chat-review');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
