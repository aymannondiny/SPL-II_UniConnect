import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/view/widgets/forgot_password_form.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_recovery_scope.dart';

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
            ForgotPasswordForm(controller: controller),
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
