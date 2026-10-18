import 'package:flutter/material.dart';

/// Summary tile placeholders preserve the reference layout without fabricated counts.
class HomeSummaryTiles extends StatelessWidget {
  const HomeSummaryTiles({required this.onFeature, super.key});
  final ValueChanged<String> onFeature;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final item in [
        ('Connections', 'connection requests'),
        ('Clubs & events', 'events this week'),
        ('Career board', 'new career posts'),
      ])
        Tooltip(
          message: 'Activity counts are not available yet.',
          child: SizedBox(
            width: 150,
            child: Material(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onFeature(item.$1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(
                        '—',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
