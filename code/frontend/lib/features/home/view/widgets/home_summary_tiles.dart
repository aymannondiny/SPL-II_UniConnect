import 'package:flutter/material.dart';

/// Useful shortcuts while activity summary endpoints are not available.
class HomeSummaryTiles extends StatelessWidget {
  const HomeSummaryTiles({
    required this.onFeature,
    this.alumni = false,
    super.key,
  });
  final ValueChanged<String> onFeature;
  final bool alumni;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in [
          ('Connections', Icons.people_outline, 'Your connections'),
          (
            'Clubs & events',
            Icons.calendar_today_outlined,
            'Explore clubs & events',
          ),
          (
            'Career board',
            Icons.work_outline,
            alumni ? 'Share career opportunities' : 'Browse opportunities',
          ),
        ])
          SizedBox(
            width: constraints.maxWidth.clamp(0.0, 210.0),
            child: Material(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onFeature(item.$1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$2, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$3,
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
      ],
    ),
  );
}
