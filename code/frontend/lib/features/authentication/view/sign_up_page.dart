import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_page_shell.dart';
import 'package:uniconnect/features/authentication/controller/registration_controller.dart';
import 'package:uniconnect/features/authentication/data/registration_repository.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/view/widgets/registration_form.dart';
import 'package:uniconnect/features/authentication/view/widgets/verification_pending.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({this.repository, super.key});
  final RegistrationRepository? repository;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  ApiClient? _client;
  late final RegistrationController _controller;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ?? ApiRegistrationRepository(_client = ApiClient());
    _controller = RegistrationController(repository);
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
      header: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Flexible(child: Text('Already a member?')),
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
            child: const Text('Log in'),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (_, _) => _controller.result == null
            ? RegistrationForm(controller: _controller)
            : VerificationPending(controller: _controller),
      ),
    );
  }
}
