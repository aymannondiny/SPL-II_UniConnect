import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/authentication/data/session_repository.dart';

class UniConnectApp extends StatefulWidget {
  const UniConnectApp({
    this.initialPath,
    this.sessionRepository,
    this.appearanceStore,
    super.key,
  });

  final String? initialPath;
  final SessionRepository? sessionRepository;
  final AppearanceStore? appearanceStore;

  @override
  State<UniConnectApp> createState() => _UniConnectAppState();
}

class _UniConnectAppState extends State<UniConnectApp> {
  late final AppearanceController _appearance;

  @override
  void initState() {
    super.initState();
    _appearance = AppearanceController(store: widget.appearanceStore);
    unawaited(_appearance.restore());
  }

  @override
  void dispose() {
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.initialPath ?? AppRoutes.home;
    return SessionHost(
      repository: widget.sessionRepository,
      child: ThemePreference(
        controller: _appearance,
        child: ValueListenableBuilder(
          valueListenable: _appearance,
          builder: (_, mode, _) => MaterialApp(
            title: 'UniConnect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: mode == AppearanceMode.engineering
                ? AppTheme.engineering()
                : AppTheme.dark(),
            themeMode: mode == AppearanceMode.light
                ? ThemeMode.light
                : ThemeMode.dark,
            initialRoute: route,
            onGenerateInitialRoutes: (name) => [
              AppRouter.onGenerateRoute(RouteSettings(name: name)),
            ],
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        ),
      ),
    );
  }
}
