import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/model/club_workspace_context.dart';
import 'package:uniconnect/features/club/view/club_home_page.dart';

import '../../tool/support/campus_fixture_api.dart';
import '../../tool/support/fake_session_repository.dart';

void main() {
  testWidgets(
    'overview retries failures and refreshes after returning from management',
    (tester) async {
      final session = SessionController(FakeSessionRepository());
      await session.login('member@iut-dhaka.edu', 'test-password');
      final fixture = CampusFixtureApi();
      var fail = true;
      var reads = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/clubs/1') {
            reads++;
            if (fail) return http.Response('{}', 503);
          }
          return http.Response.fromStream(
            await fixture.client.send(
              http.Request(request.method, request.url)
                ..headers.addAll(request.headers)
                ..bodyBytes = request.bodyBytes,
            ),
          );
        }),
      );
      final repository = ClubRepository(client, session);
      Widget app(bool active) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClubHomePage(
              repository: repository,
              clubContext: const ClubWorkspaceContext(
                contextType: 'CLUB',
                clubId: 1,
                assignmentId: 10,
                clubName: 'Programming Club',
                clubRole: 'REPRESENTATIVE',
              ),
              active: active,
              onManage: () {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(true));
      await tester.pumpAndSettle();
      expect(find.text('Overview unavailable'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Publishing is active'), findsOneWidget);
      expect(reads, 2);
      await tester.pumpWidget(app(false));
      await tester.pumpAndSettle();
      expect(reads, 2);
      await tester.pumpWidget(app(true));
      await tester.pumpAndSettle();
      expect(reads, 3);
      await tester.tap(find.text('Refresh overview'));
      await tester.pumpAndSettle();
      expect(reads, 4);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
      client.close();
      fixture.client.close();
    },
  );
}
