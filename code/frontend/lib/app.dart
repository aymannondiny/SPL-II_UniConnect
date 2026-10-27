import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/authentication/data/session_repository.dart';

class UniConnectApp extends StatefulWidget {
  const UniConnectApp({
    this.resetLink,
    this.initialPath,
    this.sessionRepository,
    super.key,
  });

  final PasswordResetLink? resetLink;
  final String? initialPath;
  final SessionRepository? sessionRepository;

  @override
  State<UniConnectApp> createState() => _UniConnectAppState();
}

class _UniConnectAppState extends State<UniConnectApp> {
  final _theme = ValueNotifier(ThemeMode.dark);

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.resetLink != null
        ? AppRoutes.resetPassword
        : widget.initialPath ?? AppRoutes.home;
    return SessionHost(
      repository: widget.sessionRepository,
      child: ThemePreference(
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
                RouteSettings(name: name, arguments: widget.resetLink),
              ),
            ],
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        ),
      ),
    );
  }
}
