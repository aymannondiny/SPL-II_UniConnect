import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/administration/view/administration_section_picker.dart';

void main() {
  for (final width in [1440.0, 390.0, 320.0]) {
    testWidgets('accounts and reports remain discoverable at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AdministrationSectionPicker(
                selected: 0,
                accountsEnabled: true,
                reportsEnabled: true,
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      if (width < 800) {
        expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
        await tester.tap(find.text('Academic catalog'));
        await tester.pumpAndSettle();
      } else {
        expect(find.byType(SegmentedButton<int>), findsOneWidget);
      }
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();
      expect(selected, 3);
      expect(tester.takeException(), isNull);
    });
  }
}
