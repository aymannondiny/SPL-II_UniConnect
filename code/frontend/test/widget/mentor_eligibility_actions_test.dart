import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile.dart';
import 'package:uniconnect/features/mentorship/model/mentor_profile_missing.dart';
import 'package:uniconnect/features/mentorship/view/mentorship_page.dart';

import '../../tool/support/fake_mentorship_repository.dart';
import '../../tool/support/fake_session_repository.dart';

class UnregisteredMentorshipRepository extends StubMentorshipRepository {
  @override
  Future<MentorProfile> getMyMentorProfile() async =>
      throw const MentorProfileMissing();
}

void main() {
  for (final scenario in [
    (role: 'STUDENT', year: 1, registered: false, register: false),
    (role: 'STUDENT', year: 2, registered: false, register: true),
    (role: 'ALUMNI', year: null, registered: false, register: true),
    (role: 'ALUMNI', year: null, registered: true, register: false),
  ]) {
    testWidgets(
      'mentor actions follow eligibility and registration: $scenario',
      (tester) async {
        final session = SessionController(FakeSessionRepository());
        session.account = CurrentAccount(
          userId: 1,
          fullName: 'Member',
          email: 'member@iut-dhaka.edu',
          platformRole: scenario.role,
        );
        addTearDown(session.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MentorshipPage(
                  session: session,
                  repository: scenario.registered
                      ? StubMentorshipRepository()
                      : UnregisteredMentorshipRepository(),
                  yearOfStudy: scenario.year,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Become Mentor'),
          scenario.register ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Host Session'),
          scenario.registered ? findsOneWidget : findsNothing,
        );
        expect(find.text('Discover Sessions'), findsOneWidget);
        await tester.ensureVisible(find.text('My Mentorship'));
        await tester.tap(find.text('My Mentorship'));
        await tester.pumpAndSettle();
        expect(
          find.text('Register as Mentor'),
          scenario.register ? findsWidgets : findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
