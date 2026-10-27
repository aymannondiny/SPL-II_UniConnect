import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/home/view/widgets/feature_card.dart';
import 'package:uniconnect/features/home/view/widgets/campus_features.dart';

/// Administration landing page links to real workflows, without invented counts.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({required this.onFeature, super.key});
  final ValueChanged<String> onFeature;

  static const _areas = [
    CampusFeature(
      'Report queue',
      'Review submitted reports and record supported moderation outcomes.',
      Icons.flag_outlined,
      'Moderation',
      featured: true,
    ),
    CampusFeature(
      'Account management',
      'Find accounts, inspect details, suspend or restore access.',
      Icons.manage_accounts_outlined,
      'Accounts',
    ),
    CampusFeature(
      'Club requests',
      'Review student requests to establish a university club.',
      Icons.playlist_add_check_outlined,
      'Clubs',
    ),
    CampusFeature(
      'Club administration',
      'Create clubs, appoint administrators and manage club publishing.',
      Icons.account_balance_outlined,
      'Clubs',
      featured: true,
    ),
    CampusFeature(
      'Academic catalog',
      'Maintain departments, programmes and degree options.',
      Icons.menu_book_outlined,
      'Catalog',
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionCard(
        title: 'Administration overview',
        subtitle: 'Manage the university community',
        child: Text(
          'Review reports, manage account access and keep campus information up to date.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 600
              ? 2
              : 1;
          final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final area in _areas)
                SizedBox(
                  width: width,
                  child: FeatureCard(
                    feature: area,
                    compact: columns == 1,
                    onTap: () => onFeature(area.title),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
