import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/view/verify_password_reset_page.dart';
import 'package:uniconnect/features/authentication/view/sign_up_page.dart';
import 'package:uniconnect/features/authentication/view/email_verification_page.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';
import 'package:uniconnect/features/authentication/view/forgot_password_page.dart';
import 'package:uniconnect/features/authentication/view/reset_password_page.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String signUp = '/sign-up';
  static const String verifyEmail = '/verify-email';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String verifyPasswordReset = '/verify-password-reset';
  static const String resetPassword = '/reset-password';
  static const String workspace = '/home';
  static const String connections = '/connections';
  static const String discover = '/discover';
  static const String chat = '/chat';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.workspace => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => SessionScope.of(context).account == null
            ? const LoginPage()
            : AuthenticatedWorkspace(
                initialFeature: settings.arguments as String?,
              ),
      ),
      AppRoutes.connections => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => SessionScope.of(context).account == null
            ? const LoginPage()
            : const AuthenticatedWorkspace(initialFeature: 'Connections'),
      ),
      AppRoutes.discover => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => SessionScope.of(context).account == null
            ? const LoginPage()
            : const AuthenticatedWorkspace(initialFeature: 'Discover'),
      ),
      AppRoutes.login => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginPage(),
      ),
      AppRoutes.chat => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          final session = SessionScope.of(context);
          final recipient = settings.arguments as ChatConnection?;
          return session.account == null
              ? const LoginPage()
              : ChatPage(
                  sessionController: session,
                  initialRecipient: recipient,
                  openRequestId: recipient == null ? 0 : 1,
                );
        },
      ),
      AppRoutes.forgotPassword => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ForgotPasswordPage(),
      ),
      AppRoutes.verifyPasswordReset => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => settings.arguments is String
            ? VerifyPasswordResetPage(email: settings.arguments! as String)
            : const ForgotPasswordPage(),
      ),
      AppRoutes.resetPassword => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ResetPasswordPage(),
      ),
      AppRoutes.verifyEmail => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            EmailVerificationPage(email: settings.arguments as String? ?? ''),
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
