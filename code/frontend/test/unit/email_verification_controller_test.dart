import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/controller/email_verification_controller.dart';
import 'package:uniconnect/features/authentication/data/email_verification_repository.dart';
import 'package:uniconnect/features/authentication/model/verification_failure.dart';

class ControlledVerificationRepository implements EmailVerificationRepository {
  final pending = Completer<void>();
  int verifyCalls = 0;
  int resendCalls = 0;
  bool failResend = false;

  @override
  Future<void> verify(String email, String code) async {
    verifyCalls++;
    await pending.future;
  }

  @override
  Future<void> resend(String email) async {
    resendCalls++;
    if (failResend) throw const VerificationFailure('Cannot reach UniConnect');
  }
}

void main() {
  test(
    'blocks duplicate and competing requests while verifying and after success',
    () async {
      final repository = ControlledVerificationRepository();
      final controller = EmailVerificationController(repository);
      addTearDown(controller.dispose);
      final request = controller.verify('member@iut-dhaka.edu', '012345');
      await controller.verify('member@iut-dhaka.edu', '012345');
      await controller.resend('member@iut-dhaka.edu');
      expect(repository.verifyCalls, 1);
      expect(repository.resendCalls, 0);
      expect(controller.busy, isTrue);
      repository.pending.complete();
      await request;
      await controller.verify('member@iut-dhaka.edu', '012345');
      await controller.resend('member@iut-dhaka.edu');
      expect(controller.verified, isTrue);
      expect(controller.busy, isFalse);
      expect(repository.verifyCalls, 1);
      expect(repository.resendCalls, 0);
    },
  );

  test('resend failure never claims delivery and can be retried', () async {
    final repository = ControlledVerificationRepository()..failResend = true;
    final controller = EmailVerificationController(repository);
    addTearDown(controller.dispose);
    await controller.resend('member@iut-dhaka.edu');
    expect(controller.resendError, 'Cannot reach UniConnect');
    expect(controller.resendNotice, isNull);
    expect(controller.verified, isFalse);
    repository.failResend = false;
    await controller.resend('member@iut-dhaka.edu');
    expect(controller.resendError, isNull);
    expect(controller.resendNotice, contains('If your account is eligible'));
    expect(repository.resendCalls, 2);
  });

  test(
    'verification transport failure permits retry without false success',
    () async {
      final repository = ControlledVerificationRepository();
      final controller = EmailVerificationController(repository);
      addTearDown(controller.dispose);
      final request = controller.verify('member@iut-dhaka.edu', '012345');
      repository.pending.completeError(
        const VerificationFailure('Connection failed'),
      );
      await request;
      expect(controller.verified, isFalse);
      expect(controller.error, 'Connection failed');
      expect(controller.busy, isFalse);
    },
  );
}
