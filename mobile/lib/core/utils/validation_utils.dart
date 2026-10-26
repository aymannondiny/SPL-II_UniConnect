import 'password_policy.dart';

class ValidationUtils {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validateUniversityEmail(String? value) {
    final emailError = validateEmail(value);

    if (emailError != null) {
      return emailError;
    }

    final email = value!.trim().toLowerCase();

    // Change this domain based on your backend rule if needed
    if (!email.endsWith('@iut-dhaka.edu')) {
      return 'Use your university email address';
    }

    return null;
  }

  static String? validatePassword(String? value) =>
      PasswordPolicy.validate(value);

  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirm password is required';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }
}
