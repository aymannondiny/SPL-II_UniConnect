import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/widgets/home_feature_grid.dart';
import 'package:uniconnect/features/home/view/widgets/home_banner.dart';
import 'package:uniconnect/features/profile/model/personal_profile.dart';
import 'package:uniconnect/features/home/view/engineering_home_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.name,
    required this.profile,
    required this.onProfile,
    required this.onFeature,
    this.administrator = false,
    this.access,
    super.key,
  });
  final bool administrator;
  final WorkspaceAccess? access;
  WorkspaceAccess get permissions =>
      access ??
      WorkspaceAccess(
        role: administrator ? 'SYSTEM_ADMIN' : profile?.role ?? 'STUDENT',
      );
  final String name;
  final PersonalProfile? profile;
  final VoidCallback onProfile;
  final ValueChanged<String> onFeature;
  @override
  Widget build(BuildContext context) {
    if (EngineeringTheme.active(context)) {
      return EngineeringHomePage(
        name: name,
        profile: profile,
        access: permissions,
        onFeature: onFeature,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeBanner(
          name: name,
          onFeature: onFeature,
          alumni: permissions.role == 'ALUMNI',
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              permissions.role == 'ALUMNI'
                  ? 'Your alumni workspace'
                  : 'Your student workspace',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Text('Choose a space to jump in.'),
          ],
        ),
        const SizedBox(height: 20),
        HomeFeatureGrid(
          onFeature: onFeature,
          onProfile: onProfile,
          administrator: administrator,
          access: permissions,
        ),
      ],
    );
  }
}
