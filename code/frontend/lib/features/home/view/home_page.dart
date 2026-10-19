import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/home/view/widgets/home_feature_grid.dart';
import 'package:uniconnect/features/home/view/widgets/home_banner.dart';
import 'package:uniconnect/features/profile/model/personal_profile.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.name,
    required this.profile,
    required this.onProfile,
    required this.onFeature,
    this.administrator = false,
    super.key,
  });
  final String name;
  final PersonalProfile? profile;
  final VoidCallback onProfile;
  final ValueChanged<String> onFeature;
  final bool administrator;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HomeBanner(name: name, onFeature: onFeature),
      const SizedBox(height: 28),
      Wrap(
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Everything in UniConnect',
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
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) {
          final events = SectionCard(
            title: 'Coming up on campus',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Campus events will appear here when updates are available.',
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => onFeature('Clubs & events'),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Explore clubs & events'),
                ),
              ],
            ),
          );
          final people = SectionCard(
            title: 'People you may know',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover students and alumni across your community.',
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => onFeature('Discover'),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Discover people'),
                ),
              ],
            ),
          );
          return constraints.maxWidth >= 820
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: events),
                    const SizedBox(width: 20),
                    Expanded(child: people),
                  ],
                )
              : Column(children: [events, const SizedBox(height: 20), people]);
        },
      ),
      const SizedBox(height: 24),
      SectionCard(
        title: 'Your place in the community',
        subtitle: profile == null
            ? 'Welcome to your UniConnect workspace.'
            : '${profile!.role == 'ALUMNI' ? 'Alumni' : 'Student'} · ${profile!.academicLabel}',
        child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onProfile,
            icon: const Icon(Icons.person_outline),
            label: const Text('Manage my profile'),
          ),
        ),
      ),
    ],
  );
}
