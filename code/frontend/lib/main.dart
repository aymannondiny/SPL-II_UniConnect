import 'package:flutter/material.dart';
import 'package:uniconnect/app.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:uniconnect/core/routing/verification_history.dart';
import 'package:uniconnect/features/authentication/model/verification_link.dart';

void main() {
  usePathUrlStrategy();
  final link = VerificationLink.fromUri(Uri.base);
  if (link != null) clearVerificationFragment();
  runApp(UniConnectApp(verificationLink: link));
}
