import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';
import 'package:uniconnect/features/notification/model/app_notification.dart';
import 'package:uniconnect/features/notification/view/notification_target_navigator.dart';

import '../../tool/support/fake_mentorship_repository.dart';
import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/workflow_fixture_api.dart';

class TrackingMentorshipRepository extends StubMentorshipRepository {
  int? openedId;
  @override
  Future<MentorshipSlot> getSlotDetails(int slotId) {
    openedId = slotId;
    return super.getSlotDetails(slotId);
  }
}

void main() {
  for (final width in [1440.0, 390.0]) {
    for (final type in ['PROJECT', 'MENTORSHIP_SLOT', 'REPORT', 'UNKNOWN']) {
      testWidgets('$type notification opens its referenced ID at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = SessionController(FakeSessionRepository());
        await tester.runAsync(
          () => session.login('member@example.org', 'test-password'),
        );
        addTearDown(session.dispose);
        final fixture = WorkflowFixtureApi();
        final client = ApiClient(client: fixture.client);
        addTearDown(client.close);
        final mentorship = TrackingMentorshipRepository();
        String? destination;
        await tester.pumpWidget(
          SessionScope(
            controller: session,
            child: MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => unawaited(
                      NotificationTargetNavigator(
                        client: client,
                        session: session,
                        onFeature: (value) => destination = value,
                        onChat: (_) {},
                        mentorshipRepository: mentorship,
                      ).open(
                        context,
                        AppNotification(
                          id: 1,
                          type: 'UPDATE',
                          title: 'Update',
                          message: 'Open',
                          referenceType: type,
                          referenceId: type == 'REPORT' ? 12 : 3,
                          createdAt: DateTime.utc(2026, 10, 25),
                          readAt: null,
                        ),
                      ),
                    ),
                    child: const Text('Open notification'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open notification'));
        await tester.pumpAndSettle();
        switch (type) {
          case 'PROJECT':
            expect(destination, 'Project finder');
            expect(find.text('Campus collaboration project 3'), findsOneWidget);
            expect(find.text('Arif Hasan'), findsOneWidget);
            expect(
              fixture.requests.any(
                (request) => request.url.path == '/api/v1/projects/3',
              ),
              isTrue,
            );
          case 'MENTORSHIP_SLOT':
            expect(destination, 'Mentorship');
            expect(mentorship.openedId, 3);
            expect(
              find.text('Dynamic Programming Masterclass'),
              findsOneWidget,
            );
          case 'REPORT':
            expect(destination, 'My reports');
            expect(find.text('Report #12'), findsOneWidget);
            expect(
              fixture.requests.any(
                (request) => request.url.path == '/api/v1/reports/12',
              ),
              isTrue,
            );
          default:
            expect(
              find.text('This notification destination is not supported yet.'),
              findsOneWidget,
            );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
