import 'package:flutter/material.dart';
import 'package:uniconnect/app.dart';
import 'package:flutter/foundation.dart';
import 'package:uniconnect/core/routing/configure_url_strategy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  final initialUri = kIsWeb ? Uri.base : Uri(path: '/');
  runApp(
    UniConnectApp(initialPath: initialUri.path.isEmpty ? '/' : initialUri.path),
  );
}
