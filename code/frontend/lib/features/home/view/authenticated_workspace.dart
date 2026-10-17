import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/home/view/home_page.dart';
import 'package:uniconnect/features/home/view/workspace_shell.dart';
import 'package:uniconnect/features/profile/controller/profile_controller.dart';
import 'package:uniconnect/features/profile/data/profile_repository.dart';
import 'package:uniconnect/features/profile/view/profile_setup_page.dart';

/// Loads owner state once per authenticated workspace; 404 starts onboarding.
class AuthenticatedWorkspace extends StatefulWidget {
  const AuthenticatedWorkspace({this.repository, super.key});
  final ProfileRepository? repository;
  @override
  State<AuthenticatedWorkspace> createState() => _AuthenticatedWorkspaceState();
}

class _AuthenticatedWorkspaceState extends State<AuthenticatedWorkspace> {
  final _client = ApiClient();
  ProfileController? _profile;
  late SessionController _session;
  bool _editing = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = SessionScope.of(context);
    if (_profile == null && _session.account!.platformRole != 'SYSTEM_ADMIN') {
      _profile = ProfileController(
        widget.repository ?? ApiProfileRepository(_client, _session),
      )..load();
    }
  }

  @override
  void dispose() {
    _profile?.dispose();
    _client.close();
    super.dispose();
  }

  void _unavailable(String feature) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(feature),
      content: const Text(
        'This space is coming soon. Your home and personal profile are ready to use.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final controller = _profile;
    if (controller == null) {
      return _shell(
        const Text(
          'Administrator workspace. Personal profiles are available for Student and Alumni accounts.',
        ),
        false,
        false,
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final setup = controller.loaded && !controller.readyForHome;
        Widget body;
        if (controller.loading) {
          body = const Center(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading your profile',
              ),
            ),
          );
        } else if (!controller.loaded) {
          body = Column(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 16),
              Text(controller.error ?? 'Unable to load your profile.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          );
        } else if (setup || _editing) {
          body = ProfileSetupPage(
            account: _session.account!,
            controller: controller,
            onSaved: () {
              _session.updateName(controller.profile!.name);
              setState(() => _editing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your profile has been saved.')),
              );
            },
            onCancel: setup ? null : () => setState(() => _editing = false),
          );
        } else {
          body = HomePage(
            name: controller.profile!.name,
            profile: controller.profile,
            onProfile: () => setState(() => _editing = true),
            onFeature: _unavailable,
          );
        }
        return _shell(body, setup || _editing, controller.loaded && !setup);
      },
    );
  }

  Widget _shell(Widget child, bool selected, bool homeEnabled) =>
      WorkspaceShell(
        name: _session.account!.fullName,
        role: _session.account!.platformRole,
        profileSelected: selected,
        busy: _session.busy || (_profile?.saving ?? false),
        error: _session.failure?.message,
        onHome: homeEnabled && !(_profile?.saving ?? false)
            ? () => setState(() => _editing = false)
            : null,
        onProfile: () {
          if (!(_profile?.saving ?? false)) setState(() => _editing = true);
        },
        onLogout: _session.logout,
        onFeature: _unavailable,
        child: child,
      );
}
