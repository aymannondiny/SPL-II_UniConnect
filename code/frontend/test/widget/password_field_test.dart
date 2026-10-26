import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_field.dart';

void main() {
  testWidgets('guidance appears only after a failed password attempt', (
    tester,
  ) async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: form,
            child: PasswordField(
              controller: controller,
              enabled: true,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    final guide = find.textContaining('Try 12+ characters');
    expect(guide, findsNothing);
    await tester.enterText(find.byType(TextFormField), '12345678');
    await tester.pump();
    expect(guide, findsNothing);
    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(guide, findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'R7!mQ2#vL9@x');
    expect(form.currentState!.validate(), isTrue);
    await tester.pumpAndSettle();
    expect(guide, findsNothing);
  });

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

    controller.text = 'R7!mQ2#vL9@x';
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
