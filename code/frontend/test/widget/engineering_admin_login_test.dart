import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/app.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/administration/view/engineering_admin_home_page.dart';
import 'package:uniconnect/features/administration/data/admin_dashboard_repository.dart';
import 'package:uniconnect/features/administration/model/admin_dashboard_summary.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';
import 'package:uniconnect/features/reporting/view/reports_page.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';
import '../support/dashboard_capture.dart';

class _EngineeringStore implements AppearanceStore {
  String? value = 'engineering';

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _SummaryRepository implements AdminDashboardRepository {
  _SummaryRepository(this.value);

  final AdminDashboardSummary value;
  int calls = 0;

  @override
  Future<AdminDashboardSummary> summary() async {
    calls++;
    return value;
  }
}

const _summary = AdminDashboardSummary(
  totalUsers: 38,
  activeClubs: 6,
  publishedPosts: 14,
  openReports: 3,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDashboardFonts);

  testWidgets(
    'Engineering login preserves form and campus state across appearance changes',
    (tester) async {
      tester.view.physicalSize = const Size(1680, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final captureKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: UniConnectApp(
            initialPath: AppRoutes.login,
            sessionRepository: FakeSessionRepository(),
            appearanceStore: _EngineeringStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('engineering-login-shell')), findsOneWidget);
      expect(
        find.byKey(const Key('engineering-campus-light-arc')),
        findsOneWidget,
      );
      expect(find.text('Log in to UniConnect'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'member@iut-dhaka.edu',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.ensureVisible(find.text('Daylight'));
      await tester.tap(find.text('Daylight'));
      await tester.pumpAndSettle();
      expect(find.text('Evening'), findsOneWidget);

      await tester.tap(find.byKey(const Key('appearance-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light Mode'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('engineering-login-shell')), findsNothing);

      await tester.tap(find.byKey(const Key('appearance-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Engineering Mode'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(0))
            .controller!
            .text,
        'member@iut-dhaka.edu',
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        'password',
      );
      expect(find.text('Evening'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureDashboard(tester, captureKey, 'engineering-login-1680');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Engineering administrator dashboard uses real admin routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1680, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final captureKey = GlobalKey();
    final session = SessionController(FakeSessionRepository());
    await session.login('admin@iut-dhaka.edu', 'test-password');
    session.account = const CurrentAccount(
      userId: 1,
      fullName: 'Ayman Administrator',
      email: 'admin@iut-dhaka.edu',
      platformRole: 'SYSTEM_ADMIN',
    );
    final campus = CampusFixtureApi(role: 'SYSTEM_ADMIN');
    final campusClient = ApiClient(client: campus.client);
    final workflow = WorkflowFixtureApi(role: 'SYSTEM_ADMIN');
    final workflowClient = ApiClient(client: workflow.client);
    final summaryRepository = _SummaryRepository(_summary);
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
            apiClient: workflowClient,
            clubRepository: ClubRepository(campusClient, session),
            adminDashboardRepository: summaryRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('engineering-admin-dashboard')),
      findsOneWidget,
    );
    expect(find.textContaining('Administration overview'), findsOneWidget);
    expect(find.text('Moderation Queue'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(summaryRepository.calls, 1);
    expect(find.text('Report queue'), findsOneWidget);
    expect(find.text('Account management'), findsOneWidget);
    expect(find.text('Club requests'), findsOneWidget);
    expect(find.byTooltip('Log out'), findsOneWidget);
    expect(find.text('C. Engineering / CSE Vibe Dashboard'), findsNothing);
    expect(
      workflow.requests.any(
        (request) => request.url.path.startsWith('/api/v1/admin/'),
      ),
      isFalse,
    );

    await tester.ensureVisible(find.text('Review Reports'));
    await tester.tap(find.text('Review Reports'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsPage), findsOneWidget);
    expect(
      workflow.requests.any(
        (request) => request.url.path == '/api/v1/admin/reports',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    await captureDashboard(tester, captureKey, 'engineering-admin-1680');
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('Engineering login remains scrollable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UniConnectApp(
          initialPath: AppRoutes.login,
          sessionRepository: FakeSessionRepository(),
          appearanceStore: _EngineeringStore(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('engineering-login-shell')), findsOneWidget);
      await tester.ensureVisible(find.text('Log in'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Engineering admin content remains scrollable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.engineering(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EngineeringAdminHomePage(
                name: 'Ayman Administrator',
                onFeature: (_) {},
                summary: _summary,
                summaryLoading: false,
                summaryError: null,
                onRetrySummary: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('engineering-admin-dashboard')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Academic Catalog'));
      expect(tester.takeException(), isNull);
    });
  }
}
