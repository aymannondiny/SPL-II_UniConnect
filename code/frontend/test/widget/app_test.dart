import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/app.dart';

void main() {
  testWidgets('loads the UniConnect application shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UniConnectApp());

    expect(find.text('UniConnect'), findsOneWidget);
    expect(
      find.text('University networking and collaboration'),
      findsOneWidget,
    );
    expect(find.text('Application foundation ready'), findsOneWidget);
  });
}
