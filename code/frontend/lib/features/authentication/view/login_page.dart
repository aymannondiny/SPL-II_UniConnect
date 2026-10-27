import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/authentication/data/session_repository.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_page_shell.dart';
import 'package:uniconnect/features/authentication/view/widgets/login_form.dart';
import 'package:uniconnect/features/home/view/authenticated_workspace.dart';
import 'package:uniconnect/features/profile/data/profile_repository.dart';

/// Authentication presentation; session lifetime belongs to SessionHost.
class LoginPage extends StatelessWidget {
  const LoginPage({this.repository, this.profileRepository, super.key});
  final SessionRepository? repository;
  final ProfileRepository? profileRepository;
  @override
  Widget build(BuildContext context) {
    final content = _LoginContent(profileRepository: profileRepository);
    return SessionScope.maybeOf(context) == null
        ? SessionHost(repository: repository, child: content)
        : content;
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent({this.profileRepository});
  final ProfileRepository? profileRepository;
  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (session.account != null) {
      return AuthenticatedWorkspace(repository: profileRepository);
    }
    return AuthPageShell(
      engineeringPresentation: true,
      header: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.end,
        children: [
          const Text('New to UniConnect?'),
          TextButton(
            onPressed: session.busy
                ? null
                : () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.signUp),
            child: const Text('Create account'),
          ),
        ],
      ),
      child: LoginForm(controller: session),
    );
  }
}
