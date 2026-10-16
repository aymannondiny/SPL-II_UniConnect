import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/data/auth_transport.dart';
import 'package:uniconnect/features/authentication/data/session_repository.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_page_shell.dart';
import 'package:uniconnect/features/authentication/view/widgets/login_form.dart';
import 'package:uniconnect/features/authentication/view/widgets/signed_in_panel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({this.repository, super.key});
  final SessionRepository? repository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ApiClient? _client;
  late final SessionController _controller;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ??
        ApiSessionRepository(AuthTransport(_client = ApiClient()));
    _controller = SessionController(repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return AuthPageShell(
          header: _controller.account != null
              ? null
              : Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.end,
                  children: [
                    const Text('New to UniConnect?'),
                    TextButton(
                      onPressed: _controller.busy
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.signUp,
                            ),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
          child: _controller.account == null
              ? LoginForm(controller: _controller)
              : SignedInPanel(controller: _controller),
        );
      },
    );
  }
}
