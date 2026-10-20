import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/mentorship/model/mentor_summary.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentor_card.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_empty_state.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_card.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

void main() {
  group('Mentorship Widgets Tests', () {
    testWidgets('MentorshipStatusBadge renders labels correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final colors = Theme.of(context).colorScheme;
                return Column(
                  children: [
                    MentorshipStatusBadge.mentorStatus(
                      MentorStatus.available,
                      colors,
                    ),
                    MentorshipStatusBadge.slotStatus(SlotStatus.open, colors),
                    MentorshipStatusBadge.mode(SlotMode.online, colors),
                    MentorshipStatusBadge.enrollmentStatus(
                      EnrollmentStatus.active,
                      colors,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Enrolled'), findsOneWidget);
    });

    testWidgets('MentorCard renders mentor information and responds to taps', (
      tester,
    ) async {
      bool tapped = false;
      const mentor = MentorSummary(
        mentorProfileId: 1,
        userId: 2,
        fullName: 'Dr. John Doe',
        role: 'ALUMNI',
        departmentName: 'Computer Science',
        graduationYear: 2022,
        status: MentorStatus.available,
        expertiseTopics: ['Machine Learning', 'Python'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorCard(mentor: mentor, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Dr. John Doe'), findsOneWidget);
      expect(find.text('Machine Learning'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);

      await tester.tap(find.text('View Profile'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('MentorshipSlotCard displays capacity and details', (
      tester,
    ) async {
      bool tapped = false;
      bool joined = false;
      const slot = MentorshipSlotSummary(
        slotId: 10,
        mentorProfileId: 1,
        mentorUserId: 2,
        mentorName: 'Dr. John Doe',
        topic: 'Intro to Deep Learning',
        description: 'Covers neural networks and gradient descent.',
        scheduleType: ScheduleType.weekly,
        startDate: '2026-11-01',
        startTime: '15:00:00',
        endTime: '16:30:00',
        mode: SlotMode.online,
        capacity: 10,
        currentMenteeCount: 3,
        status: SlotStatus.open,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorshipSlotCard(
              slot: slot,
              onTap: () => tapped = true,
              onJoin: () => joined = true,
            ),
          ),
        ),
      );

      expect(find.text('Intro to Deep Learning'), findsOneWidget);
      expect(find.text('Hosted by Dr. John Doe'), findsOneWidget);
      expect(find.text('3/10 enrolled'), findsOneWidget);

      await tester.tap(find.text('Details'));
      await tester.pump();
      expect(tapped, true);

      await tester.tap(find.text('Join Session'));
      await tester.pump();
      expect(joined, true);
    });

    testWidgets('MentorshipEmptyState renders message and triggers action', (
      tester,
    ) async {
      bool actionTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorshipEmptyState(
              icon: Icons.school_outlined,
              title: 'No Mentors Found',
              description:
                  'Try adjusting your topic or department search filter.',
              actionLabel: 'Clear Filters',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Mentors Found'), findsOneWidget);
      expect(
        find.text('Try adjusting your topic or department search filter.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Clear Filters'));
      await tester.pump();
      expect(actionTriggered, true);
    });
  });
}
