import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/registration_controller.dart';

class VerificationPending extends StatelessWidget {
  const VerificationPending({required this.controller, super.key});
  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_unread_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Check your inbox',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'We sent a verification link to ${controller.result!.email}. Open it to activate your account.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Your account is pending verification. Registration does not sign you in.',
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: controller.busy ? null : controller.resend,
          child: Text(controller.busy ? 'Requesting…' : 'Resend email'),
        ),
        if (controller.notice != null || controller.failure != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(controller.notice ?? controller.failure!.message),
          ),
        ],
      ],
    );
  }
}
