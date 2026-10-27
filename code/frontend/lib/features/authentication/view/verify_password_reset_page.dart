import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/view/reset_password_page.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_recovery_scope.dart';
import 'package:uniconnect/features/authentication/view/widgets/reset_code_form.dart';

class VerifyPasswordResetPage extends StatelessWidget {
  const VerifyPasswordResetPage({
    required this.email,
    this.repository,
    super.key,
  });

  final String email;
  final PasswordRecoveryRepository? repository;

  @override
  Widget build(BuildContext context) {
    return PasswordRecoveryScope(
      repository: repository,
      builder: (controller) => ResetCodeForm(
        controller: controller,
        email: email,
        onVerified: (code) => Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: AppRoutes.resetPassword),
            builder: (_) => ResetPasswordPage(
              email: email,
              code: code,
              repository: repository,
            ),
          ),
        ),
      ),
    );
  }
}
