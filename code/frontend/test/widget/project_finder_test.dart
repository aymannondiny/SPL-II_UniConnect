import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/view/project_dialogs.dart';
import 'package:uniconnect/features/project/view/project_finder_page.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';

void main() {
  late SessionController session;
  setUp(() async {
    session = SessionController(FakeSessionRepository());
    await session.login('member@example.org', 'test-password');
  });
  tearDown(() => session.dispose());

  Future<void> show(
    WidgetTester tester,
    Widget child,
    Size size,
    bool dark,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(
          body: child is ProjectCandidatesDialog
              ? child
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('finder, applied and candidate layouts at $size dark=$dark', (
        tester,
      ) async {
        final fixture = WorkflowFixtureApi();
        final client = ApiClient(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/applied')) {
              return http.Response(
                jsonEncode(
                  fixture.page([
                    {
                      'project': null,
                      'application': {
                        'id': 1,
                        'projectId': 1,
                        'applicantUserId': 1,
                        'status': 'CANCELLED_PROJECT_DELETED',
                      },
                    },
                  ]),
                ),
                200,
              );
            }
            return fixture.client.get(request.url);
          }),
        );
        addTearDown(client.close);
        final repository = ProjectRepository(client, session);
        await show(
          tester,
          ProjectFinderPage(repository: repository, session: session),
          size,
          dark,
        );
        expect(find.text('Campus collaboration project 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Applied'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Applied'));
        await tester.pumpAndSettle();
        expect(find.text('Deleted project listing'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Find teammates'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Find teammates'));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter at least one required skill to search.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
    'load more keeps submitted filters even while editing the next search',
    (tester) async {
      final requests = <Uri>[];
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('academic-options')) {
            return http.Response('{"departments":[]}', 200);
          }
          requests.add(request.url);
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'userId': requests.length,
                  'fullName': 'Student ${requests.length}',
                },
              ],
              'page': requests.length - 1,
              'size': 1,
              'totalElements': 2,
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      await show(
        tester,
        ProjectCandidatesDialog(
          repository: ProjectRepository(client, session),
          initialSkill: 'Java',
        ),
        const Size(1440, 900),
        false,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Required skills'),
        'Dart',
      );
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(requests.last.queryParametersAll['requiredSkills'], ['java']);
      expect(requests.last.queryParameters['page'], '1');
      expect(find.text('Student 1'), findsOneWidget);
      expect(find.text('Student 2'), findsOneWidget);
    },
  );

  testWidgets('late candidate responses cannot replace a newer search', (
    tester,
  ) async {
    final oldResponse = Completer<http.Response>();
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('academic-options')) {
          return http.Response('{"departments":[]}', 200);
        }
        if (request.url.queryParameters['requiredSkills'] == 'java') {
          return oldResponse.future;
        }
        return http.Response(
          '{"items":[{"userId":2,"fullName":"New result"}],"totalElements":1}',
          200,
        );
      }),
    );
    addTearDown(client.close);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectCandidatesDialog(
            repository: ProjectRepository(client, session),
            initialSkill: 'Java',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Required skills'),
      'Dart',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('New result'), findsOneWidget);
    oldResponse.complete(
      http.Response(
        '{"items":[{"userId":1,"fullName":"Old result"}],"totalElements":1}',
        200,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New result'), findsOneWidget);
    expect(find.text('Old result'), findsNothing);
  });
}
