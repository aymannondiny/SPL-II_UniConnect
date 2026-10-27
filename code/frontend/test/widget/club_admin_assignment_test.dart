import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/administration/data/admin_club_repository.dart';
import 'package:uniconnect/features/administration/model/club_administration_entry.dart';
import 'package:uniconnect/features/administration/view/club_admin_workspace.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/club/model/club.dart';
import 'package:uniconnect/features/club/model/club_page.dart';

import '../../tool/support/fake_session_repository.dart';

const student = EligibleClubAdministrator(
  id: 2,
  fullName: 'A student with a very long full name for the dropdown',
  email: 'a.very.long.student.email.address@iut-dhaka.edu',
);

class AssignmentRepository extends AdminClubRepository {
  AssignmentRepository(super.client, super.session);
  final searches = <String, Completer<List<EligibleClubAdministrator>>>{};

  @override
  Future<ClubPage<ClubAdministrationEntry>> clubs({
    String search = '',
    int page = 0,
  }) async => const ClubPage([
    ClubAdministrationEntry(
      club: Club(
        id: 1,
        name: 'Test club',
        category: 'Arts',
        description: 'Description',
        status: 'ACTIVE',
      ),
      administrators: [],
    ),
  ], 1);

  @override
  Future<List<EligibleClubAdministrator>> students({String search = ''}) =>
      (searches[search] = Completer<List<EligibleClubAdministrator>>()).future;
}

void main() {
  testWidgets('assignment fits long details and ignores stale searches', (
    tester,
  ) async {
    final client = ApiClient();
    final session = SessionController(FakeSessionRepository());
    addTearDown(client.close);
    addTearDown(session.dispose);
    final repository = AssignmentRepository(client, session);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminClubWorkspace(repository: repository),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pump();
    repository.searches['']!.complete([student]);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('${student.fullName} · ${student.email}').last);
    await tester.pumpAndSettle();
    FilledButton assignButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Assign'),
    );
    expect(assignButton().onPressed, isNotNull);
    final search = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'old');
    await tester.pump();
    expect(assignButton().onPressed, isNull);
    await tester.enterText(search, 'new');
    await tester.pump();
    repository.searches['new']!.complete([]);
    await tester.pumpAndSettle();
    repository.searches['old']!.complete([student]);
    await tester.pumpAndSettle();
    expect(find.text('No eligible students found.'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(assignButton().onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
