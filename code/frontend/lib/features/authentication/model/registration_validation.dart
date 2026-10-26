import 'password_policy.dart';

abstract final class RegistrationValidation {
  static String? fullName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Enter your full name.';
    if (name.length > 100) return 'Use no more than 100 characters.';
    return null;
  }

  static String? email(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.length > 320) return 'Use no more than 320 characters.';
    return RegExp(r'^[^\s@]+@iut-dhaka\.edu$').hasMatch(email)
        ? null
        : 'Use your IUT email ending in @iut-dhaka.edu.';
  }

  static String? password(String? value) => PasswordPolicy.validate(value);
  static int strength(String value) => PasswordPolicy.strength(value);
}
