import 'package:flutter/material.dart';
import 'package:uniconnect/features/home/view/widgets/campus_features.dart';
import 'package:uniconnect/features/home/view/widgets/feature_card.dart';

/// Featured cards span two columns, matching the updated wireframe's bento grid.
class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({
    required this.onFeature,
    required this.onProfile,
    this.administrator = false,
    super.key,
  });
  final ValueChanged<String> onFeature;
  final VoidCallback onProfile;
  final bool administrator;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1050
          ? 4
          : constraints.maxWidth >= 960
          ? 3
          : constraints.maxWidth >= 640
          ? 2
          : 1;
      final unit = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final feature in [
            ...campusFeatures.where(
              (f) => [
                'Discover',
                'Connections',
                'Messages',
                'My profile',
              ].contains(f.title),
            ),
            ...campusFeatures.where(
              (f) => ![
                'Discover',
                'Connections',
                'Messages',
                'My profile',
              ].contains(f.title) &&
                  (f.title != 'Administration' || administrator),
            ),
          ])
            SizedBox(
              width: feature.featured && columns > 1 ? unit * 2 + 16 : unit,
              child: FeatureCard(
                feature: feature,
                compact: columns == 1,
                onTap: feature.title == 'Administration' && !administrator
                    ? null
                    : feature.title == 'My profile'
                    ? onProfile
                    : () => onFeature(feature.title),
              ),
            ),
        ],
      );
    },
  );
}
