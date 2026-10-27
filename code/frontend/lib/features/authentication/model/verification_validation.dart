import 'package:uniconnect/features/authentication/model/registration_validation.dart';

abstract final class VerificationValidation {
  static String? email(String? value) => RegistrationValidation.email(value);

  /// Keep codes as strings: 012345 is different from 12345.
  static String? code(String? value) {
    if (value == null || !RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'Enter the six-digit code from your email.';
    }
    return null;
  }
}
