import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/view/workspace_shell.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_destinations.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_navigation.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(1024, 600),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('complete navigation remains reachable at $size dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? destination;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: WorkspaceShell(
              name: 'Test Member',
              profileSelected: false,
              busy: false,
              onHome: () => destination = 'Home',
              onProfile: () => destination = 'My profile',
              onLogout: () {},
              onFeature: (label) => destination = label,
              child: const Text('Workspace content'),
            ),
          ),
        );
        if (size.width < 900) {
          await tester.tap(find.text('More'));
          await tester.pumpAndSettle();
        } else {
          expect(
            tester.getSize(find.byType(TextField)).width,
            lessThanOrEqualTo(520),
          );
        }
        final navigation = find.byType(WorkspaceNavigation);
        final scrollable = find.descendant(
          of: navigation,
          matching: find.byType(Scrollable),
        );
        for (final group in workspaceGroups.entries) {
          await tester.scrollUntilVisible(
            find.descendant(of: navigation, matching: find.text(group.key)),
            120,
            scrollable: scrollable,
          );
          expect(
            find.descendant(of: navigation, matching: find.text(group.key)),
            findsOneWidget,
          );
          for (final item in group.value) {
            final target = find.descendant(
              of: navigation,
              matching: find.text(item.label),
            );
            await tester.scrollUntilVisible(
              target,
              120,
              scrollable: scrollable,
            );
            expect(target, findsOneWidget);
          }
        }
        final admin = find.descendant(
          of: navigation,
          matching: find.widgetWithText(ListTile, 'Administration'),
        );
        expect(tester.widget<ListTile>(admin).enabled, isFalse);
        final career = find.descendant(
          of: navigation,
          matching: find.text('Career board'),
        );
        await tester.scrollUntilVisible(career, -120, scrollable: scrollable);
        await tester.tap(career);
        await tester.pumpAndSettle();
        expect(destination, 'Career board');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'administrator destination is enabled only for the administrator role',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? destination;
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceShell(
            name: 'Admin',
            role: 'SYSTEM_ADMIN',
            profileSelected: false,
            busy: false,
            onHome: () {},
            onProfile: () {},
            onLogout: () {},
            onFeature: (value) => destination = value,
            child: const Text('Workspace content'),
          ),
        ),
      );
      final admin = find.widgetWithText(ListTile, 'Administration');
      await tester.ensureVisible(admin);
      expect(tester.widget<ListTile>(admin).enabled, isTrue);
      await tester.tap(admin);
      await tester.pumpAndSettle();
      expect(destination, 'Administration');
    },
  );
}
