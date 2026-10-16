import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/password_recovery_controller.dart';
import 'package:uniconnect/features/authentication/data/auth_transport.dart';
import 'package:uniconnect/features/authentication/data/password_recovery_repository.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_page_shell.dart';

/// Owns recovery dependencies and their lifetime for either recovery screen.
class PasswordRecoveryScope extends StatefulWidget {
  const PasswordRecoveryScope({
    required this.builder,
    this.repository,
    super.key,
  });
  final Widget Function(PasswordRecoveryController) builder;
  final PasswordRecoveryRepository? repository;

  @override
  State<PasswordRecoveryScope> createState() => _PasswordRecoveryScopeState();
}

class _PasswordRecoveryScopeState extends State<PasswordRecoveryScope> {
  ApiClient? _client;
  late final PasswordRecoveryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PasswordRecoveryController(
      widget.repository ??
          ApiPasswordRecoveryRepository(AuthTransport(_client = ApiClient())),
    );
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
      child: ListenableBuilder(
        listenable: _controller,
        builder: (_, _) => widget.builder(_controller),
      ),
    );
  }
}
