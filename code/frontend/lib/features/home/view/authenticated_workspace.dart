import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';
import 'package:uniconnect/features/connection/view/connection_page.dart';
import 'package:uniconnect/features/home/view/home_page.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_dimensions.dart';
import 'package:uniconnect/features/home/view/workspace_feature_page.dart';
import 'package:uniconnect/features/home/view/workspace_shell.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';
import 'package:uniconnect/features/profile/controller/profile_controller.dart';
import 'package:uniconnect/features/profile/data/profile_repository.dart';
import 'package:uniconnect/features/profile/view/profile_setup_page.dart';

/// Keeps one authenticated workspace and its visited destination states alive.
class AuthenticatedWorkspace extends StatefulWidget {
  const AuthenticatedWorkspace({
    this.repository,
    this.chatRepository,
    this.initialFeature,
    super.key,
  });

  final ProfileRepository? repository;
  final ChatRepository? chatRepository;
  final String? initialFeature;

  @override
  State<AuthenticatedWorkspace> createState() => _AuthenticatedWorkspaceState();
}

class _AuthenticatedWorkspaceState extends State<AuthenticatedWorkspace> {
  static const _destinations = <String>[
    'Home',
    'Discover',
    'Connections',
    'Messages',
    'Notifications',
    'Clubs & events',
    'Project finder',
    'Career board',
    'Mentorship',
    'My profile',
    'Administration',
    'Search',
  ];

  final _client = ApiClient();
  final Set<String> _visited = {'Home'};
  ProfileController? _profile;
  late SessionController _session;
  bool _editing = false;
  String? _activeFeature;

  String get _selectedDestination =>
      _editing ? 'My profile' : (_activeFeature ?? 'Home');

  @override
  void initState() {
    super.initState();
    _activeFeature = widget.initialFeature;
    _editing = widget.initialFeature == 'My profile';
    _visited.add(_selectedDestination);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = SessionScope.of(context);
    if (_profile == null &&
        _session.account != null &&
        _session.account!.platformRole != 'SYSTEM_ADMIN') {
      _profile = ProfileController(
        widget.repository ?? ApiProfileRepository(_client, _session),
      );
      unawaited(_profile!.load());
      if (_editing) unawaited(_profile!.prepareEditing());
    }
  }

  @override
  void dispose() {
    _profile?.dispose();
    _client.close();
    super.dispose();
  }

  void _openFeature(String feature) {
    if (feature == 'Administration' &&
        _session.account?.platformRole != 'SYSTEM_ADMIN') {
      return;
    }
    if (feature == 'My profile') {
      _openProfile();
      return;
    }
    setState(() {
      _editing = false;
      _activeFeature = feature;
      _visited.add(feature);
    });
  }

  void _openProfile() {
    final controller = _profile;
    setState(() {
      if (controller == null) {
        _editing = false;
        _activeFeature = 'My profile';
        _visited.add('My profile');
      } else {
        _editing = true;
        _activeFeature = null;
        _visited.add('My profile');
      }
    });
    if (controller != null) unawaited(controller.prepareEditing());
  }

  Widget _profileEditor(ProfileController? controller) {
    if (controller == null) {
      return const WorkspaceFeaturePage(feature: 'My profile');
    }
    if (!controller.editDataReady) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.error == null)
                const CircularProgressIndicator()
              else ...[
                Text(controller.error!),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.catalogLoading
                      ? null
                      : controller.loaded
                      ? () => unawaited(controller.prepareEditing())
                      : controller.load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return ProfileSetupPage(
      account: _session.account!,
      controller: controller,
      onSaved: () {
        _session.updateName(controller.profile!.name);
        setState(() {
          _editing = false;
          _activeFeature = null;
          _visited.add('Home');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your profile has been saved.')),
        );
      },
      onCancel: controller.readyForHome
          ? () => setState(() {
              _editing = false;
              _activeFeature = null;
              _visited.add('Home');
            })
          : null,
    );
  }

  Widget _destinationPage(String destination, ProfileController? controller) {
    if (destination == 'My profile') return _profileEditor(controller);
    if (destination == 'Home') {
      if (controller != null &&
          !controller.loaded &&
          !controller.loading &&
          controller.error != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 16),
              Text(controller.error!),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return HomePage(
        name: controller?.profile?.name ?? _session.account!.fullName,
        profile: controller?.profile,
        onProfile: _openProfile,
        onFeature: _openFeature,
      );
    }
    if (destination == 'Connections' || destination == 'Discover') {
      return ConnectionPage(
        session: _session,
        initialDiscovery: destination == 'Discover',
        onOpenMessages: () => _openFeature('Messages'),
      );
    }
    if (destination == 'Messages') {
      return ChatPage(
        sessionController: _session,
        repository: widget.chatRepository,
        embedded: true,
        active: _selectedDestination == 'Messages',
      );
    }
    return WorkspaceFeaturePage(feature: destination);
  }

  Widget _pageFrame(String destination, Widget page, bool compact) {
    if (destination == 'Messages') return page;
    return SingleChildScrollView(
      key: PageStorageKey<String>('workspace-$destination'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: workspaceContentMaxWidth),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 32),
            child: page,
          ),
        ),
      ),
    );
  }

  Widget _pageStack(ProfileController? controller, bool compact) {
    final needsSetup =
        controller != null && controller.loaded && !controller.readyForHome;
    final selected = needsSetup ? 'My profile' : _selectedDestination;
    if (!_destinations.contains(selected)) return const SizedBox.shrink();
    return IndexedStack(
      index: _destinations.indexOf(selected),
      children: [
        for (final destination in _destinations)
          if (!_visited.contains(destination) && destination != selected)
            SizedBox.shrink(key: ValueKey(destination))
          else
            _pageFrame(
              destination,
              _destinationPage(destination, controller),
              compact,
            ),
      ],
    );
  }

  Widget _shell(Widget child, bool selected, bool homeEnabled) =>
      WorkspaceShell(
        name: _session.account!.fullName,
        role: _session.account!.platformRole,
        profileSelected: selected,
        selectedFeature: selected ? null : _activeFeature,
        busy: _session.busy || (_profile?.saving ?? false),
        error: _session.failure?.message,
        onHome: homeEnabled && !(_profile?.saving ?? false)
            ? () => setState(() {
                _editing = false;
                _activeFeature = null;
                _visited.add('Home');
              })
            : null,
        onProfile: _openProfile,
        onLogout: _session.logout,
        onFeature: _openFeature,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    if (_session.account == null) return const LoginPage();
    final controller = _profile;
    final compact =
        MediaQuery.sizeOf(context).width < workspaceCompactBreakpoint;
    if (controller == null) {
      return _shell(_pageStack(null, compact), false, true);
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final setup = controller.loaded && !controller.readyForHome;
        return _shell(
          _pageStack(controller, compact),
          setup || _editing,
          !setup,
        );
      },
    );
  }
}
