abstract final class RegistrationValidation {
  static String? fullName(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Enter your full name.'
        : null;
  }

  static String? email(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    return RegExp(r'^[^\s@]+@iut-dhaka\.edu$').hasMatch(email)
        ? null
        : 'Use your IUT email ending in @iut-dhaka.edu.';
  }

  static String? password(String? value) {
    final length = (value ?? '').length;
    return length < 8 || length > 72
        ? 'Use between 8 and 72 characters.'
        : null;
  }

  // A visual hint only; the backend accepts any password of 8–72 characters.
  static int strength(String value) {
    if (value.isEmpty) return 0;
    if (value.length < 8) return 1;
    return 1 +
        (value.length >= 8 ? 1 : 0) +
        (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)
            ? 1
            : 0) +
        (RegExp(r'[0-9\W]').hasMatch(value) ? 1 : 0);
  }
}
