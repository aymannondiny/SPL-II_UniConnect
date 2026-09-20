import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/view/welcome_page.dart';

abstract final class AppRoutes {
  static const String home = '/';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.home => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const WelcomePage(),
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
