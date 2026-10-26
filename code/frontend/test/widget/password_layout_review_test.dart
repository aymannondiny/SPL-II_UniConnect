import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/view/sign_up_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final text = FontLoader(AppTheme.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await text.load();
    await icons.load();
  });
  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    for (final dark in [false, true]) {
      testWidgets('registration screenshot $size dark=$dark', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: const SignUpPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(2), '12345678');
        await tester.enterText(find.byType(TextFormField).at(3), 'different');
        await tester.ensureVisible(find.text('Confirm password'));
        await tester.pumpAndSettle();
        expect(find.text('Password strength: weak'), findsOneWidget);
        expect(find.text('Passwords must match.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/password-review');
          await directory.create(recursive: true);
          await File(
            '${directory.path}/registration-${size.width.toInt()}-${dark ? "dark" : "light"}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
