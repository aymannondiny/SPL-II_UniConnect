import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/view/widgets/engineering_decorations.dart';

/// Engineering presentation for the system-administration context.
///
/// The backend does not currently expose dashboard aggregate counts, so the
/// four summaries intentionally render an unavailable state instead of
/// presenting fixture values as operational data.
class EngineeringAdminHomePage extends StatelessWidget {
  const EngineeringAdminHomePage({
    required this.name,
    required this.onFeature,
    super.key,
  });

  final String name;
  final ValueChanged<String> onFeature;

  static const _summaries = [
    ('Total Users', Icons.people_outline),
    ('Active Clubs', Icons.layers_outlined),
    ('Published Posts', Icons.article_outlined),
    ('Open Reports', Icons.flag_outlined),
  ];

  static const _queue = [
    (
      'Reports requiring review',
      'Open the live administrator report queue.',
      Icons.flag_outlined,
      'Report queue',
    ),
    (
      'Club creation requests',
      'Review real pending club requests.',
      Icons.playlist_add_check_outlined,
      'Club requests',
    ),
    (
      'Account moderation',
      'Inspect authorized account actions and history.',
      Icons.manage_accounts_outlined,
      'Account management',
    ),
  ];

  static const _actions = [
    ('Review Reports', Icons.flag_outlined, 'Report queue'),
    ('Manage Users', Icons.people_outline, 'Account management'),
    ('Club Administration', Icons.layers_outlined, 'Club administration'),
    ('Academic Catalog', Icons.menu_book_outlined, 'Academic catalog'),
  ];

  String get _firstName {
    final value = name.trim();
    return value.isEmpty ? 'Admin' : value.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('engineering-admin-dashboard'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _AdminHero(name: _firstName),
      const SizedBox(height: 22),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 920
              ? 4
              : constraints.maxWidth >= 520
              ? 2
              : 1;
          final gap = constraints.maxWidth < 520 ? 10.0 : 16.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in _summaries)
                SizedBox(
                  width: width,
                  child: _SummaryCard(label: item.$1, icon: item.$2),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 26),
      LayoutBuilder(
        builder: (context, constraints) {
          final queue = _EngineeringPanel(
            title: 'Moderation Queue',
            icon: Icons.layers_outlined,
            child: Column(
              children: [
                for (final item in _queue)
                  _QueueRoute(
                    title: item.$1,
                    subtitle: item.$2,
                    icon: item.$3,
                    onTap: () => onFeature(item.$4),
                  ),
              ],
            ),
          );
          final actions = _EngineeringPanel(
            title: 'Quick Actions',
            icon: Icons.bolt_outlined,
            child: LayoutBuilder(
              builder: (context, inner) {
                final columns = inner.maxWidth >= 420 ? 2 : 1;
                const gap = 12.0;
                final width = (inner.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final item in _actions)
                      SizedBox(
                        width: width,
                        child: _QuickAction(
                          label: item.$1,
                          icon: item.$2,
                          onTap: () => onFeature(item.$3),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
          if (constraints.maxWidth < 900) {
            return Column(
              children: [queue, const SizedBox(height: 20), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: queue),
              const SizedBox(width: 22),
              Expanded(flex: 4, child: actions),
            ],
          );
        },
      ),
    ],
  );
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      return SizedBox(
        height: compact ? 270 : 170,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Good Evening, '),
                        TextSpan(
                          text: '${name}_',
                          style: const TextStyle(
                            color: AppTheme.engineeringAccent,
                          ),
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: compact ? 32 : 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Administration overview of the UniConnect community.',
                    style: TextStyle(color: Color(0xFFE1C1CD), fontSize: 17),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 120,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.engineeringAccent, Color(0x006F1538)],
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              const Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 470,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: .68,
                    child: CustomPaint(painter: CampusBlueprintPainter()),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label unavailable',
    child: Container(
      constraints: const BoxConstraints(minHeight: 122),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: _panelDecoration(radius: 18),
      child: Row(
        children: [
          Icon(icon, size: 43, color: AppTheme.engineeringAccent),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '—',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                ),
                Text(label, style: const TextStyle(color: Color(0xFFE2C0CD))),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EngineeringPanel extends StatelessWidget {
  const _EngineeringPanel({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: _panelDecoration(radius: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.engineeringAccent, size: 28),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _QueueRoute extends StatelessWidget {
  const _QueueRoute({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x4D792340))),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF651332),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.engineeringAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFCDA5B4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 19),
          ],
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0x88470B25),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFA92351)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.engineeringAccent, size: 30),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

BoxDecoration _panelDecoration({required double radius}) => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE8460B24), Color(0xED260711)],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xFF9B244D)),
  boxShadow: const [
    BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 10)),
  ],
);
