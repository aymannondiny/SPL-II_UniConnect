import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/app.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/administration/data/admin_dashboard_repository.dart';
import 'package:uniconnect/features/administration/model/admin_dashboard_summary.dart';
import 'package:uniconnect/features/administration/view/admin_home_page.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/model/club_workspace_context.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';
import 'package:uniconnect/features/home/view/workspace_shell.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_session_repository.dart';

class _EngineeringStore implements AppearanceStore {
  String? value = 'engineering';

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _ControlledSummaryRepository implements AdminDashboardRepository {
  _ControlledSummaryRepository(this.load);

  final Future<AdminDashboardSummary> Function() load;
  int calls = 0;

  @override
  Future<AdminDashboardSummary> summary() {
    calls++;
    return load();
  }
}

class _DelayedAdminContextRepository extends ClubRepository {
  _DelayedAdminContextRepository(super.client, super.session);

  final selection = Completer<void>();

  @override
  Future<({ClubWorkspaceContext active, List<ClubWorkspaceContext> available})>
  workspaceContexts() async => (
    active: const ClubWorkspaceContext(contextType: 'PERSONAL'),
    available: const [
      ClubWorkspaceContext(contextType: 'PERSONAL'),
      ClubWorkspaceContext(contextType: 'SYSTEM_ADMINISTRATION'),
    ],
  );

  @override
  Future<void> selectContext(String type, {int? assignmentId}) async {
    await selection.future;
  }
}

const _positiveSummary = AdminDashboardSummary(
  totalUsers: 38,
  activeClubs: 6,
  publishedPosts: 14,
  openReports: 3,
);

void main() {
  testWidgets(
    'Engineering registration reuses the approved auth presentation',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UniConnectApp(
          initialPath: AppRoutes.signUp,
          sessionRepository: FakeSessionRepository(),
          appearanceStore: _EngineeringStore(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('engineering-login-shell')), findsOneWidget);
      expect(
        find.byKey(const Key('engineering-campus-light-arc')),
        findsOneWidget,
      );
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Alumni'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Test Member');
      await tester.tap(find.byKey(const Key('appearance-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light Mode'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('engineering-login-shell')), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Test Member',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Engineering navigation uses the shared combined destination', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.engineering(),
        home: WorkspaceShell(
          name: 'Student Member',
          profileSelected: false,
          busy: false,
          onHome: () {},
          onProfile: () {},
          onLogout: () {},
          onFeature: (value) => selected = value,
          child: const Text('Workspace'),
        ),
      ),
    );

    expect(find.text('Clubs & events'), findsOneWidget);
    expect(find.text('Clubs'), findsNothing);
    expect(find.text('Announcements'), findsNothing);
    expect(find.text('Events'), findsNothing);
    await tester.tap(find.text('Clubs & events'));
    expect(selected, 'Clubs & events');
  });

  testWidgets('Engineering administrator logout invalidates the session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeSessionRepository()..role = 'SYSTEM_ADMIN';
    final session = SessionController(repository);
    await session.login('admin@iut-dhaka.edu', 'password');
    final campus = CampusFixtureApi(role: 'SYSTEM_ADMIN');
    final client = ApiClient(client: campus.client);
    addTearDown(client.close);
    addTearDown(session.dispose);
    final summary = _ControlledSummaryRepository(() async => _positiveSummary);

    await tester.pumpWidget(
      SessionScope(
        controller: session,
        child: MaterialApp(
          theme: AppTheme.engineering(),
          home: AuthenticatedWorkspace(
            apiClient: client,
            clubRepository: ClubRepository(client, session),
            adminDashboardRepository: summary,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('engineering-admin-dashboard')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('workspace-logout')));
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 1);
    expect(session.account, isNull);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const Key('engineering-admin-dashboard')), findsNothing);
    await expectLater(
      session.accessToken(),
      throwsA(
        isA<AuthFailure>().having(
          (error) => error.sessionEnded,
          'sessionEnded',
          isTrue,
        ),
      ),
    );
  });

  testWidgets(
    'administrator summary waits for confirmed administration context',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sessionRepository = FakeSessionRepository()..role = 'SYSTEM_ADMIN';
      final session = SessionController(sessionRepository);
      await session.login('admin@iut-dhaka.edu', 'password');
      final client = ApiClient(
        client: CampusFixtureApi(role: 'SYSTEM_ADMIN').client,
      );
      final contexts = _DelayedAdminContextRepository(client, session);
      final summary = _ControlledSummaryRepository(
        () async => _positiveSummary,
      );
      addTearDown(client.close);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        SessionScope(
          controller: session,
          child: MaterialApp(
            theme: AppTheme.engineering(),
            home: AuthenticatedWorkspace(
              apiClient: client,
              clubRepository: contexts,
              adminDashboardRepository: summary,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(summary.calls, 0);
      expect(
        find.byKey(const Key('engineering-admin-dashboard')),
        findsNothing,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      contexts.selection.complete();
      await tester.pumpAndSettle();

      expect(summary.calls, 1);
      expect(
        find.byKey(const Key('engineering-admin-dashboard')),
        findsOneWidget,
      );
      expect(find.text('38'), findsOneWidget);

      await session.logout();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'administrator summaries distinguish loading, zero, and success',
    (tester) async {
      final pending = Completer<AdminDashboardSummary>();
      final repository = _ControlledSummaryRepository(() => pending.future);
      await _pumpAdminHome(tester, repository);

      expect(find.byType(CircularProgressIndicator), findsNWidgets(4));
      pending.complete(
        const AdminDashboardSummary(
          totalUsers: 0,
          activeClubs: 0,
          publishedPosts: 0,
          openReports: 0,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0'), findsNWidgets(4));
      expect(find.text('Unavailable'), findsNothing);

      await _pumpAdminHome(
        tester,
        _ControlledSummaryRepository(() async => _positiveSummary),
      );
      await tester.pumpAndSettle();
      for (final value in ['38', '6', '14', '3']) {
        expect(find.text(value), findsOneWidget);
      }
    },
  );

  for (final failure in [
    const AuthFailure('You do not have permission for this action.'),
    const AuthFailure('The request timed out. Please retry.'),
    const AuthFailure(
      'Cannot reach UniConnect. Check your connection and retry.',
    ),
  ]) {
    testWidgets('administrator summaries expose ${failure.message}', (
      tester,
    ) async {
      await _pumpAdminHome(
        tester,
        _ControlledSummaryRepository(() async => throw failure),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unavailable'), findsNWidgets(4));
      expect(find.text(failure.message), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  }

  testWidgets('malformed summary is unavailable and retry can recover', (
    tester,
  ) async {
    var attempt = 0;
    final repository = _ControlledSummaryRepository(() async {
      attempt++;
      if (attempt == 1) throw const FormatException('missing field');
      return _positiveSummary;
    });
    await _pumpAdminHome(tester, repository);
    await tester.pumpAndSettle();
    expect(
      find.text('Administrator statistics are unavailable. Please retry.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('38'), findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
    expect(repository.calls, 2);
  });
}

Future<void> _pumpAdminHome(
  WidgetTester tester,
  AdminDashboardRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.engineering(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: AdminHomePage(
            key: ValueKey(repository),
            name: 'Admin User',
            onFeature: (_) {},
            summaryRepository: repository,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
