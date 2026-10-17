import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/app.dart';

void main() {
  testWidgets('loads the sign-up screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UniConnectApp());

    expect(find.text('UniConnect'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create my account'), findsOneWidget);
  });

  testWidgets('loads login directly without passing through sign-up', (
    tester,
  ) async {
    await tester.pumpWidget(const UniConnectApp(initialPath: '/login'));
    expect(find.text('Log in to UniConnect'), findsOneWidget);
    expect(find.text('Create your account'), findsNothing);
  });

  testWidgets('loads reset recovery directly without a token', (tester) async {
    await tester.pumpWidget(
      const UniConnectApp(initialPath: '/reset-password'),
    );
    expect(find.text('This link is no longer usable'), findsOneWidget);
    expect(find.text('Request a new reset link'), findsOneWidget);
  });
}
