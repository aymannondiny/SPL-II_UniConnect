import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_error_notice.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_submit_button.dart';

/// A real session handoff until the authenticated home page is implemented.
class SignedInPanel extends StatelessWidget {
  const SignedInPanel({required this.controller, super.key});
  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthFormHeading(
          badge: 'Welcome back',
          title: 'You’re logged in',
          subtitle: 'Your campus community is one step closer.',
        ),
        Text(
          controller.account!.fullName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(controller.account!.email),
        const SizedBox(height: 24),
        const Text(
          'Your account is connected. The home and profile pages are still being built.',
        ),
        const SizedBox(height: 12),
        const Text(
          'For this version, reloading the page requires logging in again.',
        ),
        AuthErrorNotice(message: controller.failure?.message),
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: 'Log out',
          busy: controller.busy,
          onPressed: controller.logout,
        ),
      ],
    );
  }
}
