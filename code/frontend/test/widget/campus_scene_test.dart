import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/view/widgets/campus_scene.dart';

void main() {
  testWidgets('campus supports lighting, rotation and explicit playback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampusScene())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('iut-campus-scene')), findsOneWidget);
    await tester.tap(find.text('Evening'));
    await tester.pump();
    expect(find.text('Daylight'), findsOneWidget);
    await tester.tap(find.byTooltip('Rotate campus'));
    await tester.drag(
      find.byKey(const ValueKey('iut-campus-scene')),
      const Offset(70, 0),
    );
    await tester.pump();
    await tester.tap(find.text('Play motion'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Pause motion'), findsOneWidget);
    await tester.tap(find.text('Pause motion'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion does not schedule an entrance animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: CampusScene()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.text('Play motion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
