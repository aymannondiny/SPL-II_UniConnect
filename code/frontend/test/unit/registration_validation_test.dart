import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/model/registration_validation.dart';

void main() {
  test('registration names respect the later profile update limit', () {
    expect(RegistrationValidation.fullName('a' * 100), isNull);
    expect(RegistrationValidation.fullName('a' * 101), isNotNull);
    expect(RegistrationValidation.fullName('  ${'a' * 100}  '), isNull);
  });

  test('registration emails respect the persisted address length', () {
    expect(RegistrationValidation.email('${'a' * 306}@iut-dhaka.edu'), isNull);
    expect(
      RegistrationValidation.email('${'a' * 307}@iut-dhaka.edu'),
      isNotNull,
    );
  });
}
