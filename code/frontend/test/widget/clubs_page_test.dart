import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/view/clubs_page.dart';
import 'package:uniconnect/features/club/view/widgets/club_tile.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_session_repository.dart';

void main() {
  late SessionController session;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@example.org', 'test-password');
  });
  tearDown(() => session.dispose());
  for (final width in [1440.0, 390.0, 320.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'club discovery, profile, history and event detail at $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(
            width,
            width == 320
                ? 640
                : width == 390
                ? 844
                : 900,
          );
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = ClubRepository(
            ApiClient(client: CampusFixtureApi().client),
            session,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClubsPage(repository: repository),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Find your community'), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'Technology');
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await tester.pumpAndSettle();
          expect(find.byType(ClubTile), findsOneWidget);
          expect(
            tester.widget<ClubTile>(find.byType(ClubTile)).club.name,
            'Programming Club',
          );
          await tester.ensureVisible(find.text('View club →'));
          await tester.tap(find.text('View club →'));
          await tester.pumpAndSettle();
          expect(find.text('Contact: programming@example.org'), findsOneWidget);
          await tester.ensureVisible(find.text('Show this club’s updates'));
          await tester.tap(find.text('Show this club’s updates'));
          await tester.pumpAndSettle();
          final history = find.widgetWithText(ChoiceChip, 'Past events');
          await tester.ensureVisible(history);
          await tester.tap(history);
          await tester.pumpAndSettle();
          expect(find.text('Introduction to Flutter'), findsOneWidget);
          await tester.ensureVisible(find.text('View event'));
          await tester.tap(find.text('View event'));
          await tester.pumpAndSettle();
          expect(
            find.text('Registration is closed or the link is unavailable.'),
            findsOneWidget,
          );
          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();
          final all = find.widgetWithText(FilterChip, 'All clubs');
          await tester.ensureVisible(all);
          await tester.tap(all);
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ChoiceChip, 'Past events'), findsNothing);
          expect(find.text('Campus coding sprint'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets('failure can retry and empty feeds are explicit', (tester) async {
    var failure = true;
    final repository = ClubRepository(
      ApiClient(
        client: MockClient(
          (_) async => failure
              ? http.Response('{}', 503)
              : http.Response('{"items":[],"totalElements":0}', 200),
        ),
      ),
      session,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ClubsPage(repository: repository)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry clubs'), findsOneWidget);
    failure = false;
    await tester.tap(find.text('Refresh campus'));
    await tester.pumpAndSettle();
    expect(
      find.text('No clubs found. Try another name or category.'),
      findsOneWidget,
    );
    expect(
      find.text('No announcements right now. Check back for campus updates.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
