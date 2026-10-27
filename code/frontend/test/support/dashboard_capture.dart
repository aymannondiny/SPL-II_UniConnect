import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const captureDashboards = bool.fromEnvironment('CAPTURE_ROLE_DASHBOARDS');

/// Optional visual evidence uses the same bundled fonts and widgets as the app.
/// Normal tests remain read-only; enable explicitly when reviewing layout.
Future<void> loadDashboardFonts() async {
  if (!captureDashboards) return;
  final font = FontLoader('UniConnectSans');
  for (final weight in ['regular', 'medium', 'bold', 'black']) {
    font.addFont(rootBundle.load('assets/fonts/roboto-$weight.ttf'));
  }
  await font.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> captureDashboard(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  if (!captureDashboards) return;
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/role-qa');
    directory.createSync(recursive: true);
    File('${directory.path}/$filename.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
