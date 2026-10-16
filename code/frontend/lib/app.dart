import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';

class UniConnectApp extends StatelessWidget {
  const UniConnectApp({this.verificationLink, super.key});

  final VerificationLink? verificationLink;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: verificationLink == null
          ? AppRoutes.home
          : AppRoutes.verifyEmail,
      onGenerateInitialRoutes: (name) => [
        AppRouter.onGenerateRoute(
          RouteSettings(name: name, arguments: verificationLink),
        ),
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
