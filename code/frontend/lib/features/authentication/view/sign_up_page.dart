import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/controller/registration_controller.dart';
import 'package:uniconnect/features/authentication/data/registration_repository.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_hero.dart';
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
  ThemeMode _themeMode = ThemeMode.system;

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
    final inherited = Theme.of(context);
    final dark = _themeMode == ThemeMode.system
        ? inherited.brightness == Brightness.dark
        : _themeMode == ThemeMode.dark;
    return Theme(
      data: dark ? AppTheme.dark() : AppTheme.light(),
      child: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;
                final panel = Padding(
                  padding: EdgeInsets.all(compact ? 16 : 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Flexible(child: Text('Already a member?')),
                          TextButton(
                            onPressed: () => _showLoginStatus(context),
                            child: const Text('Log in'),
                          ),
                          IconButton(
                            tooltip: dark
                                ? 'Switch to light theme'
                                : 'Switch to dark theme',
                            onPressed: () => setState(
                              () => _themeMode = dark
                                  ? ThemeMode.light
                                  : ThemeMode.dark,
                            ),
                            icon: Icon(
                              dark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(compact ? 24 : 36),
                              child: ListenableBuilder(
                                listenable: _controller,
                                builder: (_, _) => _controller.result == null
                                    ? RegistrationForm(controller: _controller)
                                    : VerificationPending(
                                        controller: _controller,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return SingleChildScrollView(
                  child: compact
                      ? Column(children: [const AuthHero(compact: true), panel])
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: AuthHero(compact: false)),
                            Expanded(child: panel),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginStatus(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login screen coming next'),
        content: const Text(
          'Login is not available in this preview yet. You can create your account and request a verification email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
