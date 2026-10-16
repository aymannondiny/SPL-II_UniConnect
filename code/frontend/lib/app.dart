import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';

class UniConnectApp extends StatefulWidget {
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
  State<UniConnectApp> createState() => _UniConnectAppState();
}

class _UniConnectAppState extends State<UniConnectApp> {
  final _theme = ValueNotifier(ThemeMode.system);

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.verificationLink != null
        ? AppRoutes.verifyEmail
        : widget.resetLink != null
        ? AppRoutes.resetPassword
        : widget.initialPath ?? AppRoutes.home;
    return ThemePreference(
      controller: _theme,
      child: ValueListenableBuilder(
        valueListenable: _theme,
        builder: (_, mode, _) => MaterialApp(
          title: 'UniConnect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          initialRoute: route,
          onGenerateInitialRoutes: (name) => [
            AppRouter.onGenerateRoute(
              RouteSettings(
                name: name,
                arguments: widget.verificationLink ?? widget.resetLink,
              ),
            ),
          ],
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
