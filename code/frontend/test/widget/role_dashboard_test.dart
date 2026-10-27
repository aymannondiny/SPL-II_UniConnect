import 'package:uniconnect/features/home/view/widgets/feature_card.dart';
import 'package:uniconnect/features/reporting/view/reports_page.dart';

import '../support/dashboard_capture.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_navigation.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_profile_repository.dart';
import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDashboardFonts);
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final role in ['STUDENT', 'ALUMNI', 'SYSTEM_ADMIN']) {
      for (final dark in [false, true]) {
        testWidgets('$role dashboard and context switching at $size dark=$dark', (
          tester,
        ) async {
          final captureKey = GlobalKey();
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final session = SessionController(FakeSessionRepository());
          await session.login('member@iut-dhaka.edu', 'test-password');
          session.account = CurrentAccount(
            userId: 1,
            fullName: 'Test Member',
            email: 'member@iut-dhaka.edu',
            platformRole: role,
          );
          final campus = CampusFixtureApi(
            role: role,
            clubRole: 'REPRESENTATIVE',
          );
          final campusClient = ApiClient(client: campus.client);
          final workflow = WorkflowFixtureApi();
          final client = ApiClient(client: workflow.client);

          addTearDown(client.close);
          addTearDown(campusClient.close);
          await tester.pumpWidget(
            SessionScope(
              controller: session,
              child: MaterialApp(
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                builder: (context, child) =>
                    RepaintBoundary(key: captureKey, child: child!),
                home: AuthenticatedWorkspace(
                  repository: FakeProfileRepository()
                    ..profile = FakeProfileRepository.fixture(
                      role: role == 'SYSTEM_ADMIN' ? 'STUDENT' : role,
                    ),
                  apiClient: client,
                  clubRepository: ClubRepository(campusClient, session),
                  initialFeature: role == 'STUDENT' ? null : 'Project finder',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await captureDashboard(
            tester,
            captureKey,
            '${role.toLowerCase()}-${size.width.toInt()}-${dark ? 'dark' : 'light'}',
          );
          expect(find.text('Workspace'), findsOneWidget);
          expect(
            find.text(
              role == 'SYSTEM_ADMIN'
                  ? 'Administration overview'
                  : role == 'ALUMNI'
                  ? 'Your alumni workspace'
                  : 'Your student workspace',
            ),
            findsOneWidget,
          );
          expect(
            workflow.requests.any(
              (request) => request.url.path.startsWith('/api/v1/projects'),
            ),
            isFalse,
          );
          if (role == 'SYSTEM_ADMIN') {
            expect(find.text('Report queue'), findsWidgets);
            expect(find.text('Project finder'), findsNothing);
          } else if (role == 'ALUMNI') {
            expect(find.text('Project finder'), findsNothing);
            expect(find.text('Career board'), findsWidgets);
          }
          if (role == 'STUDENT') {
            await tester.tap(find.byType(DropdownButtonFormField<String>));
            await tester.pumpAndSettle();
            await tester.tap(
              find.text('Programming Club · Representative').last,
            );
            await tester.pumpAndSettle();
            expect(find.text('Club overview'), findsOneWidget);
            await tester.tap(find.text('Open club workspace'));
            await tester.pumpAndSettle();
            expect(find.text('Manage Programming Club'), findsOneWidget);
            expect(find.text('Edit profile'), findsNothing);
            expect(find.text('Project finder'), findsNothing);
            await tester.tap(find.byType(DropdownButtonFormField<String>));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Personal workspace').last);
            await tester.pumpAndSettle();
            expect(find.text('Your student workspace'), findsOneWidget);
            expect(find.text('Project finder'), findsWidgets);
          } else if (role == 'SYSTEM_ADMIN') {
            final reportCard = find.byWidgetPredicate(
              (widget) =>
                  widget is FeatureCard &&
                  widget.feature.title == 'Report queue',
            );
            await tester.ensureVisible(reportCard);
            await tester.tap(reportCard);
            await tester.pumpAndSettle();
            expect(find.byType(ReportsPage), findsOneWidget);
            expect(
              workflow.requests.any(
                (request) => request.url.path == '/api/v1/admin/reports',
              ),
              isTrue,
            );
            expect(
              workflow.requests.any(
                (request) => request.url.path.contains('/contexts'),
              ),
              isFalse,
            );
            expect(
              workflow.requests.any(
                (request) => request.url.path == '/api/v1/admin/academics',
              ),
              isFalse,
            );
            await tester.tap(find.byType(DropdownButtonFormField<String>));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Personal workspace').last);
            await tester.pumpAndSettle();
            expect(find.text('Administration overview'), findsNothing);
            expect(find.text('Personal workspace'), findsWidgets);
            if (size.width >= 900) {
              expect(
                find.descendant(
                  of: find.byType(WorkspaceNavigation),
                  matching: find.text('Report queue'),
                ),
                findsNothing,
              );
            }
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          session.dispose();
        });
      }
    }
  }
}
