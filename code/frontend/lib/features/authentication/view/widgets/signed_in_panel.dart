import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_error_notice.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_submit_button.dart';
import 'package:uniconnect/core/routing/app_router.dart';

/// Signed-in session actions and entry to authenticated features.
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
          'Your account is connected. Start a conversation with an accepted connection.',
        ),
        const SizedBox(height: 12),
        const Text(
          'For this version, reloading the page requires logging in again.',
        ),
        AuthErrorNotice(message: controller.failure?.message),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: controller.busy
              ? null
              : () => Navigator.pushNamed(
                  context,
                  AppRoutes.chat,
                  arguments: controller,
                ),
          icon: const Icon(Icons.forum_outlined),
          label: const Text('Open messages'),
        ),
        const SizedBox(height: 12),
        AuthSubmitButton(
          label: 'Log out',
          busy: controller.busy,
          onPressed: controller.logout,
        ),
      ],
    );
  }
}
