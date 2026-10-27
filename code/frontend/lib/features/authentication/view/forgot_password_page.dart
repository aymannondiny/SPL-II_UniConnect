import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/view/widgets/forgot_password_form.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_recovery_scope.dart';
import 'package:uniconnect/features/authentication/view/verify_password_reset_page.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({this.repository, super.key});
  final PasswordRecoveryRepository? repository;

  @override
  Widget build(BuildContext context) {
    return PasswordRecoveryScope(
      repository: repository,
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ForgotPasswordForm(
              controller: controller,
              onCodeSent: (email) => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  settings: const RouteSettings(
                    name: AppRoutes.verifyPasswordReset,
                  ),
                  builder: (_) => VerifyPasswordResetPage(
                    email: email,
                    repository: repository,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.busy
                  ? null
                  : () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.login,
                    ),
              child: const Text('Back to log in'),
            ),
          ],
        );
      },
    );
  }
}
