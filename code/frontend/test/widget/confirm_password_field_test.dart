import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/view/widgets/confirm_password_field.dart';

void main() {
  testWidgets(
    'confirmation tracks original edits and has independent visibility',
    (tester) async {
      final password = TextEditingController(text: 'R7!mQ2#vL9@x');
      final confirmation = TextEditingController();
      addTearDown(password.dispose);
      addTearDown(confirmation.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: ConfirmPasswordField(
                controller: confirmation,
                password: password,
                enabled: true,
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), password.text);
      await tester.pumpAndSettle();
      expect(find.text('Passwords must match.'), findsNothing);
      password.text = 'reef violet lantern otter';
      await tester.pumpAndSettle();
      expect(find.text('Passwords must match.'), findsOneWidget);
      await tester.tap(find.byTooltip('Show confirmation'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
      expect(password.text, 'reef violet lantern otter');
      await tester.enterText(
        find.byType(TextFormField),
        'reef violet lantern otter',
      );
      await tester.pumpAndSettle();
      expect(find.text('Passwords must match.'), findsNothing);
    },
  );
}
