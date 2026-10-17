import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';

import '../../tool/support/fake_session_repository.dart';

void main() {
  testWidgets(
    'app session survives replacing the login route and is disposed with its host',
    (tester) async {
      final repository = FakeSessionRepository();
      SessionController? first;
      SessionController? second;
      late BuildContext routeContext;
      await tester.pumpWidget(
        SessionHost(
          repository: repository,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                routeContext = context;
                first = SessionScope.of(context);
                return const Text('Login route');
              },
            ),
          ),
        ),
      );
      await first!.login('member@iut-dhaka.edu', 'password');
      if (!routeContext.mounted) {
        throw StateError('Route was unexpectedly disposed');
      }
      Navigator.of(routeContext).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) {
            second = SessionScope.of(context);
            return const Text('Protected route');
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(identical(first, second), isTrue);
      expect(second!.account!.fullName, 'Test Member');
      expect(await second!.accessToken(), 'access-login');
      expect(repository.loginCalls, 1);
      await tester.pumpWidget(const SizedBox());
      expect(first!.account, isNull);
    },
  );
}
