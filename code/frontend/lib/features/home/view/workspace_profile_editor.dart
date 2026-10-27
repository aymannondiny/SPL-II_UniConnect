part of 'authenticated_workspace.dart';

extension _WorkspaceProfileEditor on _AuthenticatedWorkspaceState {
  Widget _profileEditor(ProfileController? controller) {
    if (controller == null) {
      if (_session.account?.platformRole == 'SYSTEM_ADMIN') {
        return AdminProfilePage(
          account: _session.account!,
          session: _session,
          repository: AccountProfileRepository(_client, _session),
        );
      }
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
        _update(() {
          _editing = false;
          _activeFeature = null;
          _visited.add('Home');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your profile has been saved.')),
        );
      },
      onCancel: controller.readyForHome
          ? () => _update(() {
              _editing = false;
              _activeFeature = null;
              _visited.add('Home');
            })
          : null,
    );
  }
}
