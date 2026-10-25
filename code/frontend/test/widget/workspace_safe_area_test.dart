import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/view/workspace_shell.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('landscape content avoids display cutouts, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const content = Key('workspace-content');
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(844, 390),
              padding: EdgeInsets.only(left: 44, right: 24, bottom: 24),
              viewPadding: EdgeInsets.only(left: 44, right: 24, bottom: 24),
            ),
            child: WorkspaceShell(
              name: 'Test Member',
              profileSelected: false,
              busy: false,
              onHome: () {},
              onProfile: () {},
              onLogout: () {},
              onFeature: (_) {},
              child: const SizedBox.expand(key: content),
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(content)).dx, 44);
      expect(tester.getTopRight(find.byKey(content)).dx, 820);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
