import 'package:uniconnect/core/network/authenticated_json_client.dart';
import 'package:uniconnect/features/administration/data/account_moderation_repository.dart';
import 'package:uniconnect/features/administration/data/admin_dashboard_repository.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';
import 'package:uniconnect/features/reporting/view/reports_page.dart';
import 'package:uniconnect/features/notification/view/notification_target_navigator.dart';

import 'dart:async';

import 'package:uniconnect/features/home/controller/workspace_context_controller.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_context_switcher.dart';
import 'package:uniconnect/features/administration/view/admin_home_page.dart';
import 'package:uniconnect/features/club/view/club_management_panel.dart';
import 'package:uniconnect/features/club/view/club_home_page.dart';
import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/view/clubs_page.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/features/connection/data/connection_repository.dart';
import 'package:uniconnect/features/career/data/career_repository.dart';
import 'package:uniconnect/features/career/view/career_board_page.dart';
import 'package:uniconnect/features/chat/view/chat_page.dart';
import 'package:uniconnect/features/connection/view/connection_page.dart';
import 'package:uniconnect/features/home/view/home_page.dart';
import 'package:uniconnect/features/administration/data/admin_catalog_repository.dart';
import 'package:uniconnect/features/administration/data/admin_club_repository.dart';
import 'package:uniconnect/features/administration/view/administration_page.dart';
import 'package:uniconnect/features/notification/data/notification_repository.dart';
import 'package:uniconnect/features/notification/view/notifications_page.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/data/api_mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/view/mentorship_page.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/view/project_finder_page.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_dimensions.dart';
import 'package:uniconnect/features/home/view/workspace_feature_page.dart';
import 'package:uniconnect/features/home/view/workspace_shell.dart';
import 'package:uniconnect/features/authentication/view/login_page.dart';
import 'package:uniconnect/features/profile/controller/profile_controller.dart';
import 'package:uniconnect/features/profile/data/profile_repository.dart';
import 'package:uniconnect/features/profile/view/profile_setup_page.dart';
import 'package:uniconnect/features/profile/data/account_profile_repository.dart';
import 'package:uniconnect/features/profile/view/admin_profile_page.dart';

part 'workspace_profile_editor.dart';
part 'workspace_destination_builder.dart';

/// Keeps one authenticated workspace and its visited destination states alive.
class AuthenticatedWorkspace extends StatefulWidget {
  const AuthenticatedWorkspace({
    this.repository,
    this.apiClient,
    this.chatRepository,
    this.connectionRepository,
    this.clubRepository,
    this.careerRepository,
    this.mentorshipRepository,
    this.projectRepository,
    this.adminDashboardRepository,
    this.initialFeature,
    super.key,
  });

  final ProfileRepository? repository;
  final ApiClient? apiClient;
  final ChatRepository? chatRepository;
  final ConnectionRepository? connectionRepository;
  final ClubRepository? clubRepository;
  final CareerRepository? careerRepository;
  final MentorshipRepository? mentorshipRepository;
  final ProjectRepository? projectRepository;
  final AdminDashboardRepository? adminDashboardRepository;
  final String? initialFeature;

  @override
  State<AuthenticatedWorkspace> createState() => _AuthenticatedWorkspaceState();
}

class _AuthenticatedWorkspaceState extends State<AuthenticatedWorkspace> {
  static final _destinations = <String>[
    'Home',
    'Discover',
    'Connections',
    'Messages',
    'Notifications',
    'My reports',
    'Clubs & events',
    'Project finder',
    'Career board',
    'Mentorship',
    'My profile',
    'Administration',
    'Club workspace',
    ...WorkspaceAccess.administrationSections.keys,
  ];

  late final _client = widget.apiClient ?? ApiClient();
  final Set<String> _visited = {'Home'};
  ProfileController? _profile;
  late SessionController _session;
  WorkspaceContextController? _contexts;
  AdminDashboardRepository? _adminDashboard;
  late final ClubRepository _clubs =
      widget.clubRepository ?? ClubRepository(_client, _session);
  WorkspaceAccess get _access =>
      _contexts?.access ??
      WorkspaceAccess(role: _session.account?.platformRole ?? 'STUDENT');
  bool _canOpen(String destination) => _access.allows(destination);
  bool _editing = false;
  String? _activeFeature;
  ChatConnection? _chatTarget;
  int _chatOpenRequestId = 0;

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
    _adminDashboard ??=
        widget.adminDashboardRepository ??
        ApiAdminDashboardRepository(AuthenticatedJsonClient(_client, _session));
    if (_contexts == null && _session.account != null) {
      _contexts = WorkspaceContextController(
        _clubs,
        _session.account!.platformRole,
      );
      _contexts!.addListener(_contextChanged);
      unawaited(_contexts!.load());
    }
    if (_activeFeature == 'Administration' &&
        _session.account?.platformRole != 'SYSTEM_ADMIN') {
      _activeFeature = null;
      _visited.add('Home');
    }
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
    _contexts?.removeListener(_contextChanged);
    _contexts?.dispose();
    _profile?.dispose();
    if (widget.apiClient == null) _client.close();
    super.dispose();
  }

  void _update(VoidCallback action) => setState(action);

  void _contextChanged() {
    if (!mounted) return;
    setState(() {
      if (!_canOpen(_selectedDestination)) {
        _activeFeature = null;
        _editing = false;
      }
    });
  }

  Future<void> _switchContext(String key) async {
    if (_profile?.saving ?? false) return;
    if (await _contexts!.select(key) && mounted) {
      setState(() {
        _activeFeature = null;
        _editing = false;
        _visited
          ..clear()
          ..add('Home');
        _chatTarget = null;
      });
    }
  }

  void _openFeature(String feature) {
    if (feature == 'Search') feature = 'Discover';
    if (!_canOpen(feature) || (_contexts?.busy ?? false)) return;
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

  void _openChat(ChatConnection recipient) {
    if (!_canOpen('Messages')) return;
    setState(() {
      _editing = false;
      _activeFeature = 'Messages';
      _visited.add('Messages');
      _chatTarget = recipient;
      _chatOpenRequestId++;
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
    final requested = needsSetup ? 'My profile' : _selectedDestination;
    final selected = _canOpen(requested) ? requested : 'Home';
    if (!_destinations.contains(selected)) return const SizedBox.shrink();
    return IndexedStack(
      index: _destinations.indexOf(selected),
      children: [
        for (final destination in _destinations)
          if (!_canOpen(destination) ||
              (!_visited.contains(destination) && destination != selected))
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
        access: _access,
        contextSwitcher: _contexts == null || _access.role != 'STUDENT'
            ? null
            : WorkspaceContextSwitcher(
                controller: _contexts!,
                disabled: _session.busy || (_profile?.saving ?? false),
                onSelect: (key) => unawaited(_switchContext(key)),
              ),
        name: _session.account!.fullName,
        role: _session.account!.platformRole,
        profileSelected: selected,
        selectedFeature: selected ? null : _activeFeature,
        busy:
            _session.busy ||
            (_contexts?.busy ?? false) ||
            (_profile?.saving ?? false),
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
