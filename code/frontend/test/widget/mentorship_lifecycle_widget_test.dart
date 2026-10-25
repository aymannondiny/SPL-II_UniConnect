import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/view/widgets/host_slot_card.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_form_dialog.dart';
import 'package:uniconnect/features/mentorship/view/widgets/participation_history.dart';

import '../../tool/support/fake_mentorship_repository.dart';

void main() {
  for (final width in [1440.0, 390.0, 320.0]) {
    for (final dark in [false, true]) {
      testWidgets('history preserves rejoined periods at $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ParticipationHistory(
                  repository: StubMentorshipRepository(),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Participation History'));
        await tester.pumpAndSettle();
        expect(find.text('Dynamic Programming Masterclass'), findsNWidgets(2));
        expect(find.text('Left'), findsOneWidget);
        expect(find.text('Enrolled'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('edit retains times, recurrence end and count at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = StubMentorshipRepository();
      final controller = MentorshipController(repository);
      addTearDown(controller.dispose);
      final slot = MentorshipSlotSummary.fromJson(
        repository.slots.first.toJson()
          ..['meetingLink'] = 'https://meet.example.test/session'
          ..['meetingCount'] = 8
          ..['recurrenceEndDate'] = '2026-12-31',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentorshipSlotFormDialog(
              controller: controller,
              existingSlot: slot,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Start: 16:00'), findsOneWidget);
      expect(find.text('End: 17:30'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Series ends by 2026-12-31.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(repository.lastUpdate?.startTime, '16:00:00');
      expect(repository.lastUpdate?.endTime, '17:30:00');
      expect(repository.lastUpdate?.recurrenceEndDate, '2026-12-31');
      expect(repository.lastUpdate?.meetingCount, isNull);
    });
  }

  testWidgets(
    'closed series offers reopen; completed series has no mutation actions',
    (tester) async {
      final json = StubMentorshipRepository().slots.first.toJson()
        ..['status'] = 'CLOSED'
        ..['nextOccurrenceStartsAt'] = '2026-11-01T14:00:00';
      var reopened = false;
      Future<void> showCard() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HostSlotCard(
              slot: MentorshipSlotSummary.fromJson(json),
              onTap: () {},
              onViewAttendees: () {},
              onEdit: () {},
              onClose: () {},
              onCancel: () {},
              onReopen: () => reopened = true,
            ),
          ),
        ),
      );
      await showCard();
      await tester.tap(find.text('Reopen Enrollment'));
      expect(reopened, isTrue);
      json['status'] = 'COMPLETED';
      await showCard();
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Reopen Enrollment'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    },
  );
}
