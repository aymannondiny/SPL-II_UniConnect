import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_field.dart';

void main() {
  testWidgets('strength bars follow typing, replacement and clearing', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordField(
            controller: controller,
            enabled: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    Color bar(int index) =>
        ((tester.widget<Container>(
                  find.byKey(ValueKey('password-strength-bar-$index')),
                )).decoration!
                as BoxDecoration)
            .color!;
    final inactive = bar(0);
    expect(find.text('Password strength: enter a password'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Aa1');
    await tester.pump();
    expect(find.text('Password strength: weak'), findsOneWidget);
    expect(bar(0), isNot(inactive));
    expect(bar(1), inactive);

    controller.text = 'Password123!';
    await tester.pump();
    expect(find.text('Password strength: strong'), findsOneWidget);
    expect(bar(3), isNot(inactive));
    controller.clear();
    await tester.pump();
    expect(find.text('Password strength: enter a password'), findsOneWidget);
    expect(bar(0), inactive);
    expect(bar(3), inactive);
  });
}
