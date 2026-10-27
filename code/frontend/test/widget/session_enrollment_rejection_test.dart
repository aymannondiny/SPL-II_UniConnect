import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_details_dialog.dart';

import '../../tool/support/interactive_mentorship_repository.dart';

class _RejectedRepository extends InteractiveMentorshipRepository {
  bool full = false;
  int attempts = 0;

  @override
  Future<MentorshipSlot> getSlotDetails(int slotId) async {
    final slot = await super.getSlotDetails(slotId);
    if (!full) return slot;
    return MentorshipSlot.fromJson({
      ...slot.toJson(),
      'currentMenteeCount': 6,
      'status': 'FULL',
    });
  }

  @override
  Future<MentorshipEnrollment> joinSlot(
    int slotId,
    EnrollSlotRequest request,
  ) async {
    attempts++;
    throw const AuthFailure('The last spot was just reserved. Please refresh.');
  }
}

void main() {
  testWidgets('rejected enrollment shows error without reserving a spot', (
    tester,
  ) async {
    final repository = _RejectedRepository();
    final controller = MentorshipController(repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MentorshipSlotDetailsDialog(
            slotId: 101,
            repository: repository,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Join Session'));
    await tester.pumpAndSettle();
    expect(repository.attempts, 1);
    expect(
      find.text('The last spot was just reserved. Please refresh.'),
      findsOneWidget,
    );
    expect(find.text('2 / 6 spots filled (4 available)'), findsOneWidget);
    expect(find.text('Joined — your spot is reserved'), findsNothing);
    expect(await repository.getMyParticipation(), isEmpty);
  });

  testWidgets('full sessions cannot be joined', (tester) async {
    final repository = _RejectedRepository()..full = true;
    final controller = MentorshipController(repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MentorshipSlotDetailsDialog(
            slotId: 101,
            repository: repository,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Session Full'),
    );
    expect(button.onPressed, isNull);
    expect(repository.attempts, 0);
  });
}
