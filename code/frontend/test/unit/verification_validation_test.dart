import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/model/verification_validation.dart';

void main() {
  test('accepts exactly six ASCII digits, including leading zeros', () {
    expect(VerificationValidation.code('012345'), isNull);
    expect(VerificationValidation.code('000000'), isNull);
    for (final value in [
      null,
      '',
      '12345',
      '1234567',
      'abcdef',
      ' 012345',
      '１２３４５６',
    ]) {
      expect(VerificationValidation.code(value), isNotNull);
    }
  });
}
