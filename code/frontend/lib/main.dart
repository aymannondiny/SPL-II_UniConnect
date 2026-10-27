import 'package:flutter/material.dart';
import 'package:uniconnect/app.dart';
import 'package:flutter/foundation.dart';
import 'package:uniconnect/core/routing/configure_url_strategy.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';
import 'package:uniconnect/core/routing/reset_history.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  final initialUri = kIsWeb ? Uri.base : Uri(path: '/');
  final resetLink = PasswordResetLink.fromUri(initialUri);
  if (resetLink != null) clearResetFragment();
  runApp(
    UniConnectApp(
      resetLink: resetLink,
      initialPath: initialUri.path.isEmpty ? '/' : initialUri.path,
    ),
  );
}
