import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/project/model/project_candidate_query.dart';
import 'package:uniconnect/features/project/model/project_form_validation.dart';

void main() {
  test('skill uniqueness uses the backend whitespace and case rules', () {
    expect(
      ProjectFormValidation.skills([
        (name: ' Spring   Boot ', isRequired: true),
        (name: 'spring boot', isRequired: false),
      ]),
      'Each skill can be added only once.',
    );
    expect(
      ProjectFormValidation.skills([(name: 'Java', isRequired: false)]),
      'Add at least one required skill.',
    );
    expect(
      ProjectFormValidation.skills(
        List.generate(51, (index) => (name: 'Skill $index', isRequired: true)),
      ),
      'Use at most 50 skills.',
    );
  });

  test('capacity cannot shrink below current membership', () {
    expect(ProjectFormValidation.capacity('3', membershipCount: 4), isNotNull);
    expect(ProjectFormValidation.capacity('4', membershipCount: 4), isNull);
    expect(ProjectFormValidation.capacity('100'), isNull);
    for (final value in ['1', '101', 'two', '']) {
      expect(ProjectFormValidation.capacity(value), isNotNull);
    }
  });

  test('deadline date rolls over at midnight in Asia/Dhaka', () {
    expect(
      ProjectFormValidation.today(now: DateTime.utc(2026, 10, 25, 17, 59)),
      DateTime(2026, 10, 25),
    );
    expect(
      ProjectFormValidation.today(now: DateTime.utc(2026, 10, 25, 18)),
      DateTime(2026, 10, 26),
    );
  });

  test('candidate skills normalize and deduplicate without empty filters', () {
    expect(ProjectCandidateQuery.parseSkills(' Java, , JAVA, Spring   Boot '), [
      'java',
      'spring boot',
    ]);
  });
}
