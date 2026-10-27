part of 'authenticated_workspace.dart';

extension _WorkspaceDestinationBuilder on _AuthenticatedWorkspaceState {
  Widget _destinationPage(String destination, ProfileController? controller) {
    if (destination == 'My profile') return _profileEditor(controller);
    if (destination == 'Home') {
      if (_access.administration) return AdminHomePage(onFeature: _openFeature);
      if (_access.club) {
        return ClubHomePage(
          key: ValueKey(_access.context.key),
          repository: _clubs,
          clubContext: _access.context,
          active: _selectedDestination == 'Home',
          onManage: () => _openFeature('Club workspace'),
        );
      }
      if (_access.role == 'SYSTEM_ADMIN') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal workspace',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Use the workspace selector to return to system administration.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final feature in [
                  'Discover',
                  'Connections',
                  'Messages',
                  'Clubs & events',
                  'My reports',
                ])
                  OutlinedButton(
                    onPressed: () => _openFeature(feature),
                    child: Text(feature),
                  ),
              ],
            ),
          ],
        );
      }
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
        access: _access,
        administrator: _session.account?.platformRole == 'SYSTEM_ADMIN',
      );
    }
    if (destination == 'Club workspace' && _access.club) {
      return ClubManagementPanel(
        key: ValueKey(_access.context.key),
        repository: _clubs,
        clubContext: _access.context,
      );
    }
    if (destination == 'Administration' ||
        WorkspaceAccess.administrationSections.containsKey(destination)) {
      if (_session.account?.platformRole != 'SYSTEM_ADMIN') {
        return const SizedBox.shrink();
      }
      return AdministrationPage(
        key: ValueKey(destination),
        initialSection:
            WorkspaceAccess.administrationSections[destination] ?? 0,
        showSectionPicker: false,
        repository: AdminCatalogRepository(_client, _session),
        clubRepository: AdminClubRepository(_client, _session),
        accountRepository: AccountModerationRepository(
          AuthenticatedJsonClient(_client, _session),
        ),
        reportRepository: ReportRepository(
          AuthenticatedJsonClient(_client, _session),
        ),
        currentUserId: _session.account!.userId,
      );
    }
    if (destination == 'My reports') {
      return ReportsPage(
        repository: ReportRepository(
          AuthenticatedJsonClient(_client, _session),
        ),
      );
    }
    if (destination == 'Notifications') {
      return NotificationsPage(
        repository: ApiNotificationRepository(_client, _session),
        onOpenFeature: _openFeature,
        onOpenNotification: (item) => NotificationTargetNavigator(
          client: _client,
          session: _session,
          onFeature: _openFeature,
          onChat: _openChat,
          projectRepository: widget.projectRepository,
          mentorshipRepository: widget.mentorshipRepository,
          chatRepository: widget.chatRepository,
          clubRepository: widget.clubRepository,
          connectionRepository: widget.connectionRepository,
        ).open(context, item),
        active: _selectedDestination == 'Notifications',
      );
    }
    if (destination == 'Connections' || destination == 'Discover') {
      return ConnectionPage(
        session: _session,
        initialDiscovery: destination == 'Discover',
        onOpenMessages: _openChat,
        repository: widget.connectionRepository,
        active: _selectedDestination == destination,
      );
    }
    if (destination == 'Clubs & events') {
      return ClubsPage(
        repository: _clubs,
        active: _selectedDestination == destination,
      );
    }
    if (destination == 'Messages') {
      return ChatPage(
        sessionController: _session,
        repository: widget.chatRepository,
        embedded: true,
        active: _selectedDestination == 'Messages',
        initialRecipient: _chatTarget,
        openRequestId: _chatOpenRequestId,
      );
    }
    if (destination == 'Career board') {
      return CareerBoardPage(
        repository:
            widget.careerRepository ?? ApiCareerRepository(_client, _session),
        role: _session.account!.platformRole,
        currentUserId: _session.account!.userId,
        active: _selectedDestination == 'Career board',
      );
    }
    if (destination == 'Mentorship') {
      return MentorshipPage(
        repository:
            widget.mentorshipRepository ??
            ApiMentorshipRepository(_client, _session),
        session: _session,
        yearOfStudy:
            (controller?.profile?.json['student'] as Map?)?['yearOfStudy']
                as int?,
        active: _selectedDestination == 'Mentorship',
      );
    }
    if (destination == 'Project finder') {
      return ProjectFinderPage(
        repository:
            widget.projectRepository ?? ProjectRepository(_client, _session),
        session: _session,
        active: _selectedDestination == destination,
      );
    }
    return WorkspaceFeaturePage(feature: destination);
  }
}
