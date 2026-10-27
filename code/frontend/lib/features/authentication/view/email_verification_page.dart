import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/controller/email_verification_controller.dart';
import 'package:uniconnect/features/authentication/data/email_verification_repository.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_page_shell.dart';
import 'package:uniconnect/features/authentication/view/widgets/verification_code_form.dart';

/// Explicit code entry replaces automatic submission of emailed link tokens.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({this.email = '', this.repository, super.key});

  final String email;
  final EmailVerificationRepository? repository;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  ApiClient? _client;
  late final EmailVerificationController _controller;
  bool _openingLogin = false;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ??
        ApiEmailVerificationRepository(_client = ApiClient());
    _controller = EmailVerificationController(repository)
      ..addListener(_onVerified);
  }

  void _onVerified() {
    if (!_controller.verified || _openingLogin) return;
    _openingLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onVerified);
    _controller.dispose();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      header: TextButton(
        onPressed: () =>
            Navigator.pushReplacementNamed(context, AppRoutes.login),
        child: const Text('Back to login'),
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (_, _) =>
            VerificationCodeForm(controller: _controller, email: widget.email),
      ),
    );
  }
}
