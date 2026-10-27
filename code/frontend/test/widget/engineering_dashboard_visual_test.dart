import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_profile_repository.dart';
import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';
import '../support/dashboard_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDashboardFonts);

  testWidgets('Engineering Mode matches the approved desktop composition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1680, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final captureKey = GlobalKey();
    final session = SessionController(FakeSessionRepository());
    await session.login('member@iut-dhaka.edu', 'test-password');
    session.account = const CurrentAccount(
      userId: 1,
      fullName: 'Ayman Nondiny',
      email: 'member@iut-dhaka.edu',
      platformRole: 'STUDENT',
    );
    final campus = CampusFixtureApi(role: 'STUDENT');
    final campusClient = ApiClient(client: campus.client);
    final workflow = WorkflowFixtureApi();
    final workflowClient = ApiClient(client: workflow.client);
    addTearDown(campusClient.close);
    addTearDown(workflowClient.close);

    await tester.pumpWidget(
      SessionScope(
        controller: session,
        child: MaterialApp(
          theme: AppTheme.engineering(),
          builder: (context, child) =>
              RepaintBoundary(key: captureKey, child: child!),
          home: AuthenticatedWorkspace(
            repository: FakeProfileRepository()
              ..profile = FakeProfileRepository.fixture(
                fields: const {'fullName': 'Ayman Nondiny'},
              ),
            apiClient: workflowClient,
            clubRepository: ClubRepository(campusClient, session),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('engineering-dashboard')), findsOneWidget);
    expect(find.byKey(const Key('engineering-breadcrumb')), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.textContaining('IDEAS\nPEOPLE\nIMPACT'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureDashboard(tester, captureKey, 'engineering-1680-reference');
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
}
