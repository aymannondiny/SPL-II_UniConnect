import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/view/sign_up_page.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';
import 'package:uniconnect/features/authentication/view/email_verification_page.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';
import 'package:uniconnect/features/authentication/view/forgot_password_page.dart';
import 'package:uniconnect/features/authentication/view/reset_password_page.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String signUp = '/sign-up';
  static const String verifyEmail = '/verify-email';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String workspace = '/home';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.workspace => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => SessionScope.of(context).account == null
            ? const LoginPage()
            : const AuthenticatedWorkspace(),
      ),
      AppRoutes.login => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginPage(),
      ),
      AppRoutes.forgotPassword => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ForgotPasswordPage(),
      ),
      AppRoutes.resetPassword => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ResetPasswordPage(
          link:
              settings.arguments as PasswordResetLink? ??
              const PasswordResetLink(null),
        ),
      ),
      AppRoutes.verifyEmail => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => EmailVerificationPage(
          token: (settings.arguments as VerificationLink?)?.token,
        ),
      ),
      AppRoutes.home || AppRoutes.signUp => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SignUpPage(),
      ),
      _ => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const _UnknownRoutePage(),
      ),
    };
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: const Center(child: Text('The requested page does not exist.')),
    );
  }
}
