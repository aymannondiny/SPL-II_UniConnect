import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/home/view/home_page.dart';
import 'package:uniconnect/features/home/view/widgets/feature_card.dart';

void main() {
  testWidgets(
    'working home cards have open labels and administrator role reaches its card',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? destination;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomePage(
                name: 'Admin',
                profile: null,
                administrator: true,
                onProfile: () {},
                onFeature: (value) => destination = value,
              ),
            ),
          ),
        ),
      );
      for (final title in [
        'Discover',
        'Connections',
        'Messages',
        'My profile',
      ]) {
        final card = find.byWidgetPredicate(
          (widget) => widget is FeatureCard && widget.feature.title == title,
        );
        expect(
          find.descendant(of: card, matching: find.text('Open')),
          findsOneWidget,
        );
      }
      final admin = find.byWidgetPredicate(
        (widget) =>
            widget is FeatureCard && widget.feature.title == 'Administration',
      );
      await tester.ensureVisible(admin);
      await tester.tap(admin);
      await tester.pump();
      expect(destination, 'Administration');
      expect(tester.takeException(), isNull);
    },
  );
}
