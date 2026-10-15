import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/app.dart';

void main() {
  testWidgets('loads the sign-up screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UniConnectApp());

    expect(find.text('UniConnect'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create my account'), findsOneWidget);
  });
}
