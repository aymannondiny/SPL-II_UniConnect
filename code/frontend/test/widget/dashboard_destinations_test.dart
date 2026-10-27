import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/administration/view/administration_page.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/career/view/career_board_page.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/view/clubs_page.dart';
import 'package:uniconnect/features/connection/data/connection_repository.dart';
import 'package:uniconnect/features/connection/view/connection_page.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';
import 'package:uniconnect/features/home/view/widgets/feature_card.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_navigation.dart';
import 'package:uniconnect/features/mentorship/view/mentorship_page.dart';
import 'package:uniconnect/features/notification/view/notifications_page.dart';
import 'package:uniconnect/features/profile/view/admin_profile_page.dart';
import 'package:uniconnect/features/profile/view/profile_setup_page.dart';
import 'package:uniconnect/features/project/view/project_finder_page.dart';
import 'package:uniconnect/features/reporting/view/reports_page.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_career_repository.dart';
import '../../tool/support/fake_chat_repository.dart';
import '../../tool/support/fake_mentorship_repository.dart';
import '../../tool/support/fake_profile_repository.dart';
import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/member_fixture_api.dart';
import '../../tool/support/workflow_fixture_api.dart';

const memberPages = <String, Type>{
  'Discover': ConnectionPage,
  'Connections': ConnectionPage,
  'Messages': ChatPage,
  'Notifications': NotificationsPage,
  'Clubs & events': ClubsPage,
  'Career board': CareerBoardPage,
  'Mentorship': MentorshipPage,
  'My reports': ReportsPage,
  'My profile': ProfileSetupPage,
};

Future<void> selectDestination(
  WidgetTester tester,
  String label,
  bool mobile,
) async {
  if (mobile) {
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
  }
  final navigation = find.byType(WorkspaceNavigation);
  final target = find.descendant(
    of: navigation,
    matching: find.widgetWithText(ListTile, label),
  );
  final scrollable = find.descendant(
    of: navigation,
    matching: find.byType(Scrollable),
  );
  // Start at the beginning so every destination is reachable after any prior page.
  final state = tester.state<ScrollableState>(scrollable);
  state.position.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(target, 150, scrollable: scrollable);
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void expectHealthyPage(WidgetTester tester, Type page, String label) {
  expect(find.byType(page), findsOneWidget, reason: label);
  expect(find.textContaining('No visual-QA fixture'), findsNothing);
  expect(
    find.textContaining(
      RegExp(
        r'Unable to |Cannot reach |invalid .*response',
        caseSensitive: false,
      ),
    ),
    findsNothing,
  );
  expect(tester.takeException(), isNull, reason: label);
}

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final role in ['STUDENT', 'ALUMNI', 'SYSTEM_ADMIN']) {
      testWidgets(
        'every $role dashboard card and sidebar destination opens at $size',
        (tester) async {
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
          final workflow = WorkflowFixtureApi();
          final client = ApiClient(client: workflow.client);
          final campus = ApiClient(client: CampusFixtureApi(role: role).client);
          final members = ApiClient(client: MemberFixtureApi().client);
          await tester.pumpWidget(
            SessionScope(
              controller: session,
              child: MaterialApp(
                theme: AppTheme.light(),
                home: AuthenticatedWorkspace(
                  apiClient: client,
                  repository: FakeProfileRepository()
                    ..profile = FakeProfileRepository.fixture(
                      role: role == 'SYSTEM_ADMIN' ? 'STUDENT' : role,
                    ),
                  clubRepository: ClubRepository(campus, session),
                  connectionRepository: ConnectionRepository(members, session),
                  chatRepository: FakeChatRepository(members),
                  careerRepository: FakeCareerRepository(),
                  mentorshipRepository: StubMentorshipRepository(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final pages = role == 'SYSTEM_ADMIN'
              ? <String, Type>{
                  for (final label in [
                    'Account management',
                    'Club administration',
                    'Club requests',
                    'Report queue',
                    'Academic catalog',
                  ])
                    label: AdministrationPage,
                  'Notifications': NotificationsPage,
                  'My profile': AdminProfilePage,
                }
              : <String, Type>{
                  ...memberPages,
                  if (role == 'STUDENT') 'Project finder': ProjectFinderPage,
                };
          final cards = tester
              .widgetList<FeatureCard>(find.byType(FeatureCard))
              .map((card) => card.feature.title)
              .toList();
          for (final label in cards) {
            final card = find.byWidgetPredicate(
              (widget) =>
                  widget is FeatureCard && widget.feature.title == label,
            );
            await tester.ensureVisible(card);
            await tester.tap(card);
            await tester.pumpAndSettle();
            expectHealthyPage(tester, pages[label]!, label);
            await selectDestination(tester, 'Home', size.width < 900);
          }
          for (final entry in pages.entries) {
            await selectDestination(tester, entry.key, size.width < 900);
            expectHealthyPage(tester, entry.value, entry.key);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          session.dispose();
          client.close();
          campus.close();
          members.close();
        },
      );
    }
  }
}
