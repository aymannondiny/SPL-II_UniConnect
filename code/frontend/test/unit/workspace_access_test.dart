import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/club/model/club_workspace_context.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_destinations.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_mobile_destinations.dart';
import 'package:uniconnect/features/mentorship/model/mentor_eligibility.dart';

void main() {
  for (final role in ['STUDENT', 'ALUMNI', 'SYSTEM_ADMIN']) {
    test('$role has only permitted desktop and mobile destinations', () {
      final access = WorkspaceAccess(role: role);
      final labels = destinationsFor(access).values
          .expand((items) => items)
          .map((item) => item.label)
          .toList();
      expect(labels.contains('Project finder'), role == 'STUDENT');
      expect(labels.contains('Career board'), role != 'SYSTEM_ADMIN');
      expect(labels.contains('Mentorship'), role != 'SYSTEM_ADMIN');
      expect(labels.contains('Administration'), isFalse);
      expect(labels, everyElement(predicate<String>(access.allows)));
      expect(
        mobileDestinationsFor(access)
            .every((item) => access.allows(item.label)),
        isTrue,
      );
      for (final deferred in [
        'Search',
        'Global search',
        'Anonymize account',
        'Warnings',
      ]) {
        expect(access.allows(deferred), isFalse);
      }
    });
  }

  test(
    'management cards require both admin role and selected admin context',
    () {
      const context = ClubWorkspaceContext(
        contextType: 'SYSTEM_ADMINISTRATION',
      );
      for (final role in ['STUDENT', 'ALUMNI', 'SYSTEM_ADMIN']) {
        final access = WorkspaceAccess(role: role, context: context);
        expect(access.allows('Report queue'), role == 'SYSTEM_ADMIN');
        expect(access.allows('Account management'), role == 'SYSTEM_ADMIN');
      }
      const access = WorkspaceAccess(role: 'SYSTEM_ADMIN', context: context);
      final labels = destinationsFor(access).values
          .expand((items) => items)
          .map((item) => item.label);
      expect(labels, containsAll(WorkspaceAccess.administrationSections.keys));
      expect(labels, isNot(contains('Project finder')));
      expect(labels, isNot(contains('Messages')));
    },
  );

  test('club access requires a student assignment with a club role', () {
    const context = ClubWorkspaceContext(
      contextType: 'CLUB',
      assignmentId: 10,
      clubId: 1,
      clubRole: 'REPRESENTATIVE',
    );
    expect(
      const WorkspaceAccess(context: context).allows('Club workspace'),
      isTrue,
    );
    expect(
      const WorkspaceAccess(context: context).allows('Project finder'),
      isFalse,
    );
    expect(
      const WorkspaceAccess(role: 'ALUMNI', context: context).club,
      isFalse,
    );
    expect(
      const WorkspaceAccess(context: ClubWorkspaceContext(contextType: 'CLUB'))
          .club,
      isFalse,
    );
  });

  test(
    'mentor registration requires alumni or a student in year 2 or above',
    () {
      expect(const MentorEligibility(role: 'STUDENT').canRegister, isFalse);
      expect(
        const MentorEligibility(role: 'STUDENT', yearOfStudy: 1).canRegister,
        isFalse,
      );
      expect(
        const MentorEligibility(role: 'STUDENT', yearOfStudy: 2).canRegister,
        isTrue,
      );
      expect(const MentorEligibility(role: 'ALUMNI').canRegister, isTrue);
      expect(
        const MentorEligibility(
          role: 'SYSTEM_ADMIN',
          yearOfStudy: 3,
        ).canRegister,
        isFalse,
      );
    },
  );
}
