import 'dart:convert';

abstract final class PasswordResetValidation {
  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        password.length > 72 ||
        utf8.encode(password).length > 72) {
      return 'Use 8–72 characters and at most 72 UTF-8 bytes.';
    }
    return null;
  }
}
