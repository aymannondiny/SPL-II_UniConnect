import 'package:flutter/material.dart';
import 'package:uniconnect/app.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';

import 'support/fake_profile_repository.dart';
import 'support/fake_session_repository.dart';

/// Explicit visual-QA entry point. No fixtures are reachable from lib/main.dart.
/// Run with: flutter run -d web-server -t tool/preview.dart --web-port=3001
/// Query: ?screen=setup&role=ALUMNI&theme=dark; screen=home is the default.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final query = Uri.base.queryParameters;
  final role = query['role'] == 'ALUMNI' ? 'ALUMNI' : 'STUDENT';
  final session = SessionController(FakeSessionRepository());
  await session.login('member@iut-dhaka.edu', 'test-only-password');
  session.account = CurrentAccount(
    userId: 1,
    fullName: 'Test Member',
    email: 'member@iut-dhaka.edu',
    platformRole: role,
  );
  final repository = FakeProfileRepository();
  if (query['screen'] != 'setup') {
    repository.profile = FakeProfileRepository.fixture(role: role);
  }
  if (query['catalog'] == 'empty') repository.emptyCatalog = true;
  final theme = ValueNotifier(
    query['theme'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
  );
  runApp(
    SessionScope(
      controller: session,
      child: ThemePreference(
        controller: theme,
        child: ValueListenableBuilder(
          valueListenable: theme,
          builder: (_, mode, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'UniConnect visual QA — test fixtures',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            builder: (context, child) => LayoutBuilder(
              builder: (context, constraints) {
                final requested = double.tryParse(query['width'] ?? '');
                final width = requested == null
                    ? constraints.maxWidth
                    : requested.clamp(280.0, constraints.maxWidth);
                return Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(size: Size(width, constraints.maxHeight)),
                      child: child!,
                    ),
                  ),
                );
              },
            ),
            home: ListenableBuilder(
              listenable: session,
              builder: (_, _) => session.account == null
                  ? const UniConnectApp()
                  : AuthenticatedWorkspace(repository: repository),
            ),
          ),
        ),
      ),
    ),
  );
}
