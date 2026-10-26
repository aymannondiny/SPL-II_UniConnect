import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/password_policy.dart';

void main() {
  for (final value in [
    '12345678',
    '987654321',
    'Password123!',
    'P@ssw0rd123!',
    'Qwerty123!xyz',
    'abcdEF12!xyZ',
    'zyxwV!293mR',
    'aaaaQ7!xyz',
    'Ab1!Ab1!Ab1!',
    '        ',
    'short',
  ]) {
    test('rejects predictable password: $value', () {
      expect(PasswordPolicy.validate(value), isNotNull);
      expect(PasswordPolicy.strength(value), 1);
    });
  }
  test('ratings require length and variety or a long distinct passphrase', () {
    expect(PasswordPolicy.strength(''), 0);
    expect(PasswordPolicy.strength('reefOtter'), 2);
    expect(PasswordPolicy.strength('Reef7!ox'), 3);
    expect(PasswordPolicy.strength('R7!mQ2#vL9@x'), 4);
    expect(PasswordPolicy.strength('reef violet lantern otter'), 4);
    expect(PasswordPolicy.strength('reef reef reef reef reef'), isNot(4));
    expect(PasswordPolicy.strength('123 456 789 012'), isNot(4));
    expect(PasswordPolicy.strength('a b c d                     '), isNot(4));
  });
  test('enforces BCrypt byte limit without trimming secrets', () {
    expect(PasswordPolicy.validate('éøßñüçåöäèêî' * 3), isNotNull);
    expect(PasswordPolicy.validate("R7!mQ2#vL9@x${'éøßñüç' * 5}"), isNull);
    expect(PasswordPolicy.validate("R7!mQ2#vL9@x${'éøßñüç' * 5}é"), isNotNull);
    expect(PasswordPolicy.validate(' reef violet lantern otter '), isNull);
  });
}
