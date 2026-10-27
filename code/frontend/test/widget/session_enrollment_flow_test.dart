import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/view/mentorship_page.dart';
import 'package:uniconnect/features/mentorship/view/widgets/enrolled_session_card.dart';

import '../../tool/support/fake_session_repository.dart';
import '../../tool/support/interactive_mentorship_repository.dart';

void main() {
  for (final role in ['STUDENT', 'ALUMNI']) {
    for (final width in [1440.0, 390.0, 320.0]) {
      testWidgets('$role joins from details and sees history at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = SessionController(FakeSessionRepository());
        session.account = CurrentAccount(
          userId: 1,
          fullName: 'Viewer',
          email: 'viewer@iut-dhaka.edu',
          platformRole: role,
        );
        addTearDown(session.dispose);
        final repository = InteractiveMentorshipRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MentorshipPage(
                  repository: repository,
                  session: session,
                  yearOfStudy: 2,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Discover Sessions'));
        await tester.tap(find.text('Discover Sessions'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Details'));
        await tester.tap(find.text('Details'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 6 spots filled (4 available)'), findsOneWidget);
        await tester.tap(
          find.widgetWithText(FilledButton, 'Join Session').last,
        );
        await tester.pumpAndSettle();
        expect(find.text('3 / 6 spots filled (3 available)'), findsOneWidget);
        expect(find.text('Joined — your spot is reserved'), findsOneWidget);
        expect((await repository.getMyParticipation()).length, 1);
        await tester.tap(find.text('View My Mentorship'));
        await tester.pumpAndSettle();
        expect(find.byType(EnrolledSessionCard), findsOneWidget);
        await tester.ensureVisible(find.text('Participation History'));
        await tester.tap(find.text('Participation History'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Joined 20'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test(
    'preview prevents duplicate joins and preserves leave/rejoin history',
    () async {
      final repository = InteractiveMentorshipRepository();
      await repository.joinSlot(101, const EnrollSlotRequest());
      await expectLater(
        repository.joinSlot(101, const EnrollSlotRequest()),
        throwsException,
      );
      expect((await repository.getSlotDetails(101)).currentMenteeCount, 3);
      await repository.leaveSlot(101);
      expect((await repository.getSlotDetails(101)).currentMenteeCount, 2);
      await repository.joinSlot(101, const EnrollSlotRequest());
      expect((await repository.getMyParticipation()).length, 2);
    },
  );
}
