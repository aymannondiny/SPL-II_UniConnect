import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/email_verification_controller.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/view/widgets/verification_recovery_form.dart';

class VerificationStatusPanel extends StatelessWidget {
  const VerificationStatusPanel({required this.controller, super.key});

  final EmailVerificationController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.status;
    final verified = status == EmailVerificationStatus.verified;
    final verifying = status == EmailVerificationStatus.verifying;
    final title = switch (status) {
      EmailVerificationStatus.verifying => 'Verifying your email',
      EmailVerificationStatus.verified => 'Your email has been verified',
      EmailVerificationStatus.invalidLink => 'This link is no longer usable',
      EmailVerificationStatus.failed => 'We could not verify your email',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: verifying
                ? const CircularProgressIndicator(
                    semanticsLabel: 'Verifying email',
                  )
                : Icon(
                    verified ? Icons.mark_email_read_outlined : Icons.link_off,
                    size: 36,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
        ),
        const SizedBox(height: 16),
        Text(
          verified
              ? 'Welcome to your campus community. Your IUT email is confirmed '
                    'and your account is ready. Log in to get started.'
              : verifying
              ? 'Please wait while we confirm your IUT email address.'
              : controller.error!,
          style: const TextStyle(height: 1.6),
        ),
        if (!verifying) ...[
          const SizedBox(height: 24),
          if (status == EmailVerificationStatus.failed) ...[
            FilledButton(
              onPressed: controller.verify,
              child: const Text('Try again'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
            icon: const Icon(Icons.login),
            label: const Text('Click to log in'),
          ),
          if (verified) ...[
            const SizedBox(height: 16),
            const Text('Email verified. You are not signed in yet.'),
          ] else
            VerificationRecoveryForm(controller: controller),
        ],
      ],
    );
  }
}
