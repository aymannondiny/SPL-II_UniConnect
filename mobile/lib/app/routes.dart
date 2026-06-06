import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/providers/verify_email_provider.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/verify_email_token_screen.dart';
import '../features/home/presentation/screens/dashboard_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String verifyEmailToken = '/verify-email-token';
  static const String dashboard = '/dashboard';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static Map<String, WidgetBuilder> routes = {
    register: (context) => const RegisterScreen(),

    login: (context) => const LoginScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),

    dashboard: (context) => const DashboardScreen(),

    emailVerification: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final email = args is String ? args : '';

      return EmailVerificationScreen(
        email: email,
        onResendEmail: (email) async {
          return context
              .read<VerifyEmailProvider>()
              .resendVerificationEmail(email);
        },
      );
    },

    verifyEmailToken: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final token = args is String ? args : '';

      return VerifyEmailTokenScreen(token: token);
    },
  };
}