import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/widgets/meeting_link.dart';

void main() {
  testWidgets('meeting button launches its HTTPS address', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MeetingLink(url: 'https://meet.example.org/session'),
        ),
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'launch');
    expect(
      (calls.single.arguments as Map)['url'],
      'https://meet.example.org/session',
    );
  });

  testWidgets('invalid meeting address shows an actionable error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MeetingLink(url: 'javascript:alert(1)')),
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Unable to open this meeting link. Check the address and try again.',
      ),
      findsOneWidget,
    );
  });
}
