abstract final class LoginValidation {
  static String? email(String? value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())
        ? null
        : 'Enter a valid email address.';
  }

  // Login must accept existing credentials without imposing new signup rules.
  static String? password(String? value) {
    return value == null || value.isEmpty ? 'Enter your password.' : null;
  }
}
