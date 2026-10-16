import 'package:flutter/material.dart';
import 'package:uniconnect/app.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:uniconnect/core/routing/verification_history.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';
import 'package:uniconnect/features/authentication/model/password_reset_link.dart';
import 'package:uniconnect/core/routing/reset_history.dart';

void main() {
  usePathUrlStrategy();
  final link = VerificationLink.fromUri(Uri.base);
  final resetLink = PasswordResetLink.fromUri(Uri.base);
  if (link != null) clearVerificationFragment();
  if (resetLink != null) clearResetFragment();
  runApp(
    UniConnectApp(
      verificationLink: link,
      resetLink: resetLink,
      initialPath: Uri.base.path.isEmpty ? '/' : Uri.base.path,
    ),
  );
}
