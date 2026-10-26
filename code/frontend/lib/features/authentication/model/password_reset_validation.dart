import 'password_policy.dart';

abstract final class PasswordResetValidation {
  static String? password(String? value) => PasswordPolicy.validate(value);
}
