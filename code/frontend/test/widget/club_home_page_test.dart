import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/model/club_workspace_context.dart';
import 'package:uniconnect/features/club/view/club_home_page.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_session_repository.dart';
import '../support/dashboard_capture.dart';

void main() {
  setUpAll(loadDashboardFonts);
  for (final width in [1440.0, 390.0, 320.0]) {
    for (final dark in [false, true]) {
      testWidgets('Club overview at $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = SessionController(FakeSessionRepository());
        await session.login('member@iut-dhaka.edu', 'test-password');

        final client = ApiClient(client: CampusFixtureApi().client);
        addTearDown(client.close);
        var opened = false;
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClubHomePage(
                      repository: ClubRepository(client, session),
                      clubContext: const ClubWorkspaceContext(
                        contextType: 'CLUB',
                        clubId: 1,
                        assignmentId: 10,
                        clubName: 'Programming Club',
                        clubRole: 'CLUB_ADMINISTRATOR',
                      ),
                      active: true,
                      onManage: () => opened = true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Club overview'), findsOneWidget);
        expect(find.text('Publishing is active'), findsOneWidget);
        expect(find.text('New event'), findsNothing);
        await captureDashboard(
          tester,
          key,
          'club-home-${width.toInt()}-${dark ? 'dark' : 'light'}',
        );
        await tester.tap(find.text('Open club workspace'));
        expect(opened, isTrue);
        await tester.ensureVisible(find.text('Coming up next'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();
      });
    }
  }
}
