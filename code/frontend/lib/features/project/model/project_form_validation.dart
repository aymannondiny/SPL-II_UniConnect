/// Client-side rules shared with the project recruitment API.
class ProjectFormValidation {
  static const maxSkills = 50;

  static String normalizeSkill(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static String? skills(List<({String name, bool isRequired})> skills) {
    if (skills.isEmpty || !skills.any((skill) => skill.isRequired)) {
      return 'Add at least one required skill.';
    }
    if (skills.length > maxSkills) return 'Use at most 50 skills.';
    final names = skills.map((skill) => normalizeSkill(skill.name)).toSet();
    if (names.length != skills.length) {
      return 'Each skill can be added only once.';
    }
    return null;
  }

  static String? capacity(String? value, {int membershipCount = 1}) {
    final capacity = int.tryParse(value?.trim() ?? '');
    if (capacity == null || capacity < 2 || capacity > 100) {
      return 'Use a number from 2 to 100.';
    }
    if (capacity < membershipCount) {
      return 'Your team already has $membershipCount members.';
    }
    return null;
  }

  /// A calendar date in the backend's Asia/Dhaka deadline zone.
  static DateTime today({DateTime? now}) {
    final campus = (now ?? DateTime.now()).toUtc().add(
      const Duration(hours: 6),
    );
    return DateTime(campus.year, campus.month, campus.day);
  }
}
