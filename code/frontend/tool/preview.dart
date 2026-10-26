import 'package:flutter/material.dart';
import 'package:uniconnect/app.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';

import 'support/fake_profile_repository.dart';
import 'support/workflow_fixture_api.dart';
import 'support/fake_session_repository.dart';
import 'support/member_fixture_api.dart';
import 'support/fake_chat_repository.dart';
import 'support/campus_fixture_api.dart';
import 'support/fake_career_repository.dart';
import 'support/fake_mentorship_repository.dart';

import 'package:uniconnect/features/club/data/club_repository.dart';

import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/connection/data/connection_repository.dart';

/// Explicit visual-QA entry point. No fixtures are reachable from lib/main.dart.
/// Run with: flutter run -d web-server -t tool/preview.dart --web-port=3001
/// Query: ?screen=setup&role=ALUMNI&theme=dark; screen=home is the default.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final query = Uri.base.queryParameters;
  final role = switch (query['role']) {
    'ALUMNI' => 'ALUMNI',
    'SYSTEM_ADMIN' => 'SYSTEM_ADMIN',
    _ => 'STUDENT',
  };
  final session = SessionController(FakeSessionRepository());
  await session.login('member@iut-dhaka.edu', 'test-only-password');
  session.account = CurrentAccount(
    userId: 1,
    fullName: 'Test Member',
    email: 'member@iut-dhaka.edu',
    platformRole: role,
  );
  final workflowApi = WorkflowFixtureApi();
  final workflowClient = ApiClient(client: workflowApi.client);
  final memberApi = MemberFixtureApi();
  final campusApi = CampusFixtureApi();
  final apiClient = ApiClient(client: memberApi.client);
  final repository = FakeProfileRepository();
  if (query['screen'] != 'setup') {
    repository.profile = FakeProfileRepository.fixture(role: role);
  }
  if (query['catalog'] == 'empty') repository.emptyCatalog = true;
  final theme = ValueNotifier(
    query['theme'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
  );
  runApp(
    SessionScope(
      controller: session,
      child: ThemePreference(
        controller: theme,
        child: ValueListenableBuilder(
          valueListenable: theme,
          builder: (_, mode, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'UniConnect visual QA — test fixtures',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) => LayoutBuilder(
              builder: (context, constraints) {
                final requested = double.tryParse(query['width'] ?? '');
                final width = requested == null
                    ? constraints.maxWidth
                    : requested.clamp(280.0, constraints.maxWidth);
                return Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(size: Size(width, constraints.maxHeight)),
                      child: child!,
                    ),
                  ),
                );
              },
            ),
            home: ListenableBuilder(
              listenable: session,
              builder: (_, _) => session.account == null
                  ? const UniConnectApp()
                  : AuthenticatedWorkspace(
                      repository: repository,
                      apiClient: workflowClient,
                      connectionRepository: ConnectionRepository(
                        apiClient,
                        session,
                      ),
                      chatRepository: FakeChatRepository(apiClient),
                      clubRepository: ClubRepository(
                        ApiClient(client: campusApi.client),
                        session,
                      ),
                      mentorshipRepository: StubMentorshipRepository(),
                      careerRepository: FakeCareerRepository(),
                      initialFeature: switch (query['screen']) {
                        'projects' => 'Project finder',
                        'reports' => 'My reports',
                        'notifications' => 'Notifications',
                        'admin' => 'Administration',
                        'discover' => 'Discover',
                        'connections' => 'Connections',
                        'messages' => 'Messages',
                        'clubs' => 'Clubs & events',
                        'career' => 'Career board',
                        'mentorship' => 'Mentorship',
                        _ => null,
                      },
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
