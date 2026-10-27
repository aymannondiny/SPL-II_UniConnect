import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/mentorship/model/mentor_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/view/mentorship_page.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentor_profile_dialog.dart';

import '../../tool/support/fake_mentorship_repository.dart';
import '../../tool/support/fake_session_repository.dart';

void main() {
  for (final role in ['STUDENT', 'ALUMNI']) {
    for (final width in [1440.0, 390.0, 320.0]) {
      testWidgets('$role filters and dialog at ${width}px', (tester) async {
        tester.view.physicalSize = Size(width, 900);
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
        final repository = StubMentorshipRepository();
        repository.mentors.add(
          const MentorSummary(
            mentorProfileId: 2,
            userId: 20,
            fullName: 'Alumni Mentor',
            role: 'ALUMNI',
            status: MentorStatus.available,
            expertiseTopics: ['Java'],
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MentorshipPage(repository: repository, session: session),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final dropdown = find.byType(DropdownButtonFormField<int?>);
        await tester.ensureVisible(dropdown);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alumni').last);
        await tester.pumpAndSettle();
        expect(find.text('Alumni Mentor'), findsOneWidget);
        expect(find.text('Ayesha Siddika'), findsNothing);
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        expect(find.text('All Mentors'), findsOneWidget);
        await tester.ensureVisible(find.text('Ayesha Siddika'));
        await tester.tap(find.text('Ayesha Siddika'));
        await tester.pumpAndSettle();
        expect(find.byType(MentorProfileDialog), findsOneWidget);
        expect(find.text('Browse Sessions'), findsNothing);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Discover Sessions'));
        await tester.tap(find.text('Discover Sessions'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('In-person'));
        await tester.tap(find.text('In-person'));
        await tester.pumpAndSettle();
        expect(find.text('No Sessions Available'), findsOneWidget);
        await tester.tap(find.text('Online'));
        await tester.pumpAndSettle();
        expect(find.text('Dynamic Programming Masterclass'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'missing topic');
        await tester.pumpAndSettle();
        expect(find.text('No Sessions Available'), findsOneWidget);
        await tester.ensureVisible(find.text('Browse Mentors'));
        await tester.tap(find.text('Browse Mentors'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Discover Sessions'));
        await tester.tap(find.text('Discover Sessions'));
        await tester.pumpAndSettle();
        expect(find.text('missing topic'), findsOneWidget);
        await tester.ensureVisible(find.text('Reset'));
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        expect(find.text('Dynamic Programming Masterclass'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
