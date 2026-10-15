import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/view/sign_up_page.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String signUp = '/sign-up';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
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
