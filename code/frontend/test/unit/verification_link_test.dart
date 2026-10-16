import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';

void main() {
  test('captures the SMTP fragment only on the verification path', () {
    final token = 'a' * 43;
    final link = VerificationLink.fromUri(
      Uri.parse('https://app.example/verify-email#token=$token'),
    );
    expect(link?.token, token);
    expect(VerificationLink.isValidToken(link?.token), isTrue);
    expect(VerificationLink.fromUri(Uri.parse('https://app.example/')), isNull);
    expect(
      VerificationLink.fromUri(
        Uri.parse('https://app.example/verify-email?token=$token'),
      )?.token,
      isNull,
    );
  });

  test('handles missing, malformed and invalid tokens without throwing', () {
    for (final fragment in ['', 'token=%ZZ', 'token=short']) {
      final link = VerificationLink.fromUri(
        Uri.parse('https://app.example/verify-email#$fragment'),
      );
      expect(VerificationLink.isValidToken(link?.token), isFalse);
    }
  });
}
