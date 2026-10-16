import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_submit_button.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_recovery_scope.dart';
import 'package:uniconnect/features/authentication/view/widgets/reset_password_form.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    this.link = const PasswordResetLink(null),
    this.repository,
    super.key,
  });
  final PasswordResetLink link;
  final PasswordRecoveryRepository? repository;

  @override
  Widget build(BuildContext context) {
    return PasswordRecoveryScope(
      repository: repository,
      builder: (controller) {
        final completed = controller.completed;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!link.isValid)
              const AuthFormHeading(
                badge: 'Account help',
                title: 'This link is no longer usable',
                subtitle: 'Open the full link from your email, or request a new reset link.',
              )
            else if (completed)
              Semantics(
                liveRegion: true,
                child: const AuthFormHeading(
                  badge: 'Account help',
                  title: 'Password updated',
                  subtitle: 'Log in with your new password. You are not signed in yet.',
                ),
              )
            else
              ResetPasswordForm(controller: controller, token: link.token!),
            if (!completed) ...[
              const SizedBox(height: 12),
              AuthSubmitButton(
                label: 'Request a new reset link',
                busy: false,
                enabled: !controller.busy,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.forgotPassword,
                ),
              ),
            ],
            const SizedBox(height: 12),
            AuthSubmitButton(
              label: 'Back to log in',
              busy: false,
              enabled: !controller.busy,
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.login),
            ),
          ],
        );
      },
    );
  }
}
