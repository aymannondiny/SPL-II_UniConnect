import 'package:flutter/material.dart';
import 'package:uniconnect/app.dart';
import 'package:flutter/foundation.dart';
import 'package:uniconnect/core/routing/configure_url_strategy.dart';
import 'package:uniconnect/core/routing/verification_history.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';
import 'package:uniconnect/core/routing/reset_history.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  final initialUri = kIsWeb ? Uri.base : Uri(path: '/');
  final link = VerificationLink.fromUri(initialUri);
  final resetLink = PasswordResetLink.fromUri(initialUri);
  if (link != null) clearVerificationFragment();
  if (resetLink != null) clearResetFragment();
  runApp(
    UniConnectApp(
      verificationLink: link,
      resetLink: resetLink,
      initialPath: initialUri.path.isEmpty ? '/' : initialUri.path,
    ),
  );
}
