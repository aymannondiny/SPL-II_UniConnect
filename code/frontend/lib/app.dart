import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';

class UniConnectApp extends StatelessWidget {
  const UniConnectApp({
    this.verificationLink,
    this.resetLink,
    this.initialPath,
    super.key,
  });

  final VerificationLink? verificationLink;
  final PasswordResetLink? resetLink;
  final String? initialPath;

  @override
  Widget build(BuildContext context) {
    final route = verificationLink != null
        ? AppRoutes.verifyEmail
        : resetLink != null
        ? AppRoutes.resetPassword
        : initialPath ?? AppRoutes.home;
    return MaterialApp(
      title: 'UniConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: route,
      onGenerateInitialRoutes: (name) => [
        AppRouter.onGenerateRoute(
          RouteSettings(name: name, arguments: verificationLink ?? resetLink),
        ),
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
