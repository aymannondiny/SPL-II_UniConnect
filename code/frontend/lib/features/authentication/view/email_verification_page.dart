import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/email_verification_controller.dart';
import 'package:uniconnect/features/authentication/data/email_verification_repository.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_page_shell.dart';
import 'package:uniconnect/features/authentication/view/widgets/verification_status_panel.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({this.token, this.repository, super.key});

  final String? token;
  final EmailVerificationRepository? repository;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  ApiClient? _client;
  late final EmailVerificationController _controller;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ??
        ApiEmailVerificationRepository(_client = ApiClient());
    _controller = EmailVerificationController(repository, widget.token);
    unawaited(_controller.verify());
  }

  @override
  void dispose() {
    _controller.dispose();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      header: const Text('YOUR VERIFIED CAMPUS COMMUNITY'),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (_, _) => VerificationStatusPanel(controller: _controller),
      ),
    );
  }
}
