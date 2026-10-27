import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/view/forgot_password_page.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_recovery_scope.dart';
import 'package:uniconnect/features/authentication/view/widgets/reset_password_form.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    this.email = '',
    this.code = '',
    this.repository,
    super.key,
  });

  final String email;
  final String code;
  final PasswordRecoveryRepository? repository;

  @override
  Widget build(BuildContext context) {
    if (email.isEmpty || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      return ForgotPasswordPage(repository: repository);
    }
    return PasswordRecoveryScope(
      repository: repository,
      builder: (controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.completed)
            Semantics(
              liveRegion: true,
              child: const AuthFormHeading(
                badge: 'Account help',
                title: 'Password updated',
                subtitle:
                    'Log in with your new password. You are not signed in yet.',
              ),
            )
          else ...[
            ResetPasswordForm(controller: controller, email: email, code: code),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.busy
                  ? null
                  : () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.forgotPassword,
                    ),
              child: const Text('Request a new reset code'),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.busy
                ? null
                : () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
            child: const Text('Back to log in'),
          ),
        ],
      ),
    );
  }
}
