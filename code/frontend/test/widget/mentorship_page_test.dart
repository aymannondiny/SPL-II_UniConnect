import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/mentorship/view/mentorship_page.dart';
import 'package:uniconnect/features/mentorship/view/widgets/enrolled_session_card.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';

import '../../tool/support/fake_session_repository.dart';

import '../../tool/support/fake_mentorship_repository.dart';

void main() {
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('MentorshipPage shows enrolled session at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sessionRepo = FakeSessionRepository();
      final mentorshipRepo = _CountingMentorshipRepository();

      await tester.pumpWidget(
        SessionHost(
          repository: sessionRepo,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final session = SessionScope.of(context);
                  return SingleChildScrollView(
                    child: MentorshipPage(
                      repository: mentorshipRepo,
                      session: session,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Peer Mentorship'), findsOneWidget);
      expect(find.text('Browse Mentors'), findsOneWidget);
      expect(find.text('Discover Sessions'), findsOneWidget);
      expect(find.text('My Mentorship'), findsOneWidget);

      // Mentor directory tab is selected by default
      expect(find.text('Browse Peer Mentors'), findsOneWidget);
      expect(find.text('Ayesha Siddika'), findsOneWidget);

      // Switch to Discover Sessions tab
      await tester.ensureVisible(find.text('Discover Sessions'));
      await tester.tap(find.text('Discover Sessions'));
      await tester.pumpAndSettle();
      expect(find.text('Explore Mentorship Sessions'), findsOneWidget);
      expect(find.text('Dynamic Programming Masterclass'), findsOneWidget);

      // Switch to My Mentorship tab
      await tester.ensureVisible(find.text('My Mentorship'));
      await tester.tap(find.text('My Mentorship'));
      await tester.pumpAndSettle();
      expect(find.text('Sessions You Joined'), findsOneWidget);
      final enrolledCard = find.byType(EnrolledSessionCard);
      expect(enrolledCard, findsOneWidget);
      expect(
        find.descendant(
          of: enrolledCard,
          matching: find.text('Dynamic Programming Masterclass'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: enrolledCard,
          matching: find.text('Mentor: Ayesha Siddika'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Participation History'));
      await tester.tap(find.text('Participation History'));
      await tester.pumpAndSettle();
      expect(mentorshipRepo.historyReads, 1);
      await tester.ensureVisible(find.text('Discover Sessions'));
      await tester.tap(find.text('Discover Sessions'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('My Mentorship'));
      await tester.tap(find.text('My Mentorship'));
      await tester.pumpAndSettle();
      expect(mentorshipRepo.historyReads, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

class _CountingMentorshipRepository extends StubMentorshipRepository {
  int historyReads = 0;

  @override
  Future<List<MentorshipEnrollment>> getMyParticipation() {
    historyReads++;
    return super.getMyParticipation();
  }
}
