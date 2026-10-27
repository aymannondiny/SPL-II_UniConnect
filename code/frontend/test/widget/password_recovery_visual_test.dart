import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/view/forgot_password_page.dart';
import 'package:uniconnect/features/authentication/view/reset_password_page.dart';
import 'package:uniconnect/features/authentication/view/verify_password_reset_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      AppTheme.fontFamily,
    )..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final size in [const Size(1440, 1000), const Size(390, 1100)]) {
    for (final dark in [false, true]) {
      for (final screen in ['forgot', 'code', 'reset']) {
        final name = '$screen-${size.width.toInt()}-${dark ? "dark" : "light"}';
        testWidgets('recovery visual $name', (tester) async {
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
                debugShowCheckedModeBanner: false,
                home: switch (screen) {
                  'reset' => const ResetPasswordPage(
                    email: 'member@iut-dhaka.edu',
                    code: '012345',
                  ),
                  'code' => const VerifyPasswordResetPage(
                    email: 'member@iut-dhaka.edu',
                  ),
                  _ => const ForgotPasswordPage(),
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = Directory('build/recovery-review');
            await directory.create(recursive: true);
            await File('${directory.path}/$name.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        });
      }
    }
  }
}
