/// Registration eligibility is separate from participation and mentor ownership.
class MentorEligibility {
  const MentorEligibility({required this.role, this.yearOfStudy});

  final String role;
  final int? yearOfStudy;

  bool get canRegister =>
      role == 'ALUMNI' ||
      (role == 'STUDENT' && yearOfStudy != null && yearOfStudy! >= 2);

  String? get explanation => role == 'STUDENT' && !canRegister
      ? yearOfStudy == null
            ? 'Complete your student profile to check mentor eligibility.'
            : 'Students can become peer mentors from study year 2.'
      : null;
}
