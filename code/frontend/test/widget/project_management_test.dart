import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/project/controller/project_finder_controller.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/model/project_listing.dart';
import 'package:uniconnect/features/project/view/project_dialogs.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';

void main() {
  for (final rejectReview in [false, true]) {
    testWidgets(
      'management refreshes capacity or exposes review error: $rejectReview',
      (tester) async {
        final session = SessionController(FakeSessionRepository());
        await tester.runAsync(
          () => session.login('member@example.org', 'test-password'),
        );
        addTearDown(session.dispose);
        final fixture = WorkflowFixtureApi();
        var count = 1;
        var accepted = false;
        Map<String, dynamic> listing() => {
          ...fixture.project(1),
          'teamSizeLimit': 2,
          'membershipCount': count,
          'full': count == 2,
        };
        Map<String, dynamic> application(int id) => {
          'id': id,
          'projectId': 1,
          'applicantUserId': id + 2,
          'applicantDisplayName': 'Applicant $id',
          'status': id == 1 && accepted ? 'ACCEPTED' : 'PENDING',
        };
        http.Response json(Object data, [int status = 200]) =>
            http.Response(jsonEncode(data), status);
        final client = ApiClient(
          client: MockClient((request) async {
            final path = request.url.path;
            if (path.endsWith('/accept')) {
              if (rejectReview) {
                return json({'message': 'The team is already full.'}, 409);
              }
              accepted = true;
              count = 2;
              return json(application(1));
            }
            if (path.endsWith('/applications')) {
              return json(fixture.page([application(1), application(2)]));
            }
            if (path.endsWith('/audit')) return json(fixture.page([]));
            if (path.endsWith('/recommendations') ||
                path.endsWith('/members')) {
              return json([]);
            }
            if (path.endsWith('/1')) return json(listing());
            return json(fixture.page([listing()]));
          }),
        );
        addTearDown(client.close);
        final controller = ProjectFinderController(
          ProjectRepository(client, session),
        );
        addTearDown(controller.dispose);
        ProjectListing? editing;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: ProjectManageDialog(
                project: ProjectListing.fromJson(listing()),
                controller: controller,
                onEdit: (project) => editing = project,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Accept').first);
        await tester.pumpAndSettle();
        if (rejectReview) {
          expect(find.text('The team is already full.'), findsOneWidget);
          expect(find.text('Retry'), findsOneWidget);
        } else {
          expect(find.text('2/2 teammates · open'), findsOneWidget);
          final remainingAccept = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Accept'),
          );
          expect(remainingAccept.onPressed, isNull);
          await tester.tap(find.byTooltip('Edit listing'));
          expect(editing?.membershipCount, 2);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
