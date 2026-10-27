import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/widgets/engineering_decorations.dart';
import 'package:uniconnect/features/profile/model/personal_profile.dart';

class EngineeringHomePage extends StatelessWidget {
  const EngineeringHomePage({
    required this.name,
    required this.profile,
    required this.access,
    required this.onFeature,
    super.key,
  });

  final String name;
  final PersonalProfile? profile;
  final WorkspaceAccess access;
  final ValueChanged<String> onFeature;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Column(
      key: const Key('engineering-dashboard'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(context, compact),
        const SizedBox(height: 4),
        _featureGrid(context),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final activity = _activityPanel(context);
            final terminal = _terminalPanel(context);
            return constraints.maxWidth >= 820
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: activity),
                      const SizedBox(width: 22),
                      Expanded(child: terminal),
                    ],
                  )
                : Column(
                    children: [activity, const SizedBox(height: 20), terminal],
                  );
          },
        ),
      ],
    );
  }

  Widget _hero(BuildContext context, bool compact) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 18
        ? 'Good Afternoon'
        : 'Good Evening';
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    return SizedBox(
      key: const Key('engineering-hero'),
      height: compact ? 170 : 210,
      child: Stack(
        children: [
          Positioned(
            right: -5,
            top: compact ? 18 : 8,
            bottom: 0,
            width: compact ? 330 : 620,
            child: const Opacity(
              opacity: .8,
              child: CustomPaint(painter: CampusBlueprintPainter()),
            ),
          ),
          Positioned(
            right: 2,
            top: 15,
            width: compact ? 50 : 72,
            height: compact ? 50 : 72,
            child: const Opacity(
              opacity: .72,
              child: CustomPaint(painter: ChipPainter()),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: compact ? 43 : 55),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '> $greeting, '),
                      TextSpan(
                        text: '${firstName}_',
                        style: const TextStyle(
                          color: AppTheme.engineeringAccent,
                        ),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.engineeringText,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 26 : 44,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The IUT community for creators, builders and problem solvers.',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: const Color(0xFFEAD9DE)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid(BuildContext context) {
    final features = [
      ('Discover', 'Discover', 'People & Opportunities', Icons.search),
      ('Project finder', 'Projects', 'Build Together', Icons.layers_outlined),
      ('Clubs & events', 'Clubs', 'Join & Contribute', Icons.groups_outlined),
      ('Career board', 'Career', 'Internships & Jobs', Icons.work_outline),
    ].where((item) => access.allows(item.$1)).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final gap = columns == 4 ? 20.0 : 12.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: [
            for (final item in features)
              SizedBox(
                width: width,
                child: _EngineeringFeatureCard(
                  title: item.$2,
                  subtitle: item.$3,
                  icon: item.$4,
                  onTap: () => onFeature(item.$1),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _activityPanel(BuildContext context) => _panel(
    context,
    title: 'Recent Activity',
    child: Column(
      children: [
        _ActivityShortcut(
          icon: Icons.notifications_none,
          title: 'Review your latest notifications',
          subtitle: 'Requests, replies and campus updates',
          onTap: () => onFeature('Notifications'),
        ),
        _ActivityShortcut(
          icon: Icons.layers_outlined,
          title: 'Continue with your projects',
          subtitle: 'Open the project finder',
          accent: const Color(0xFFD77AFF),
          onTap: () => onFeature('Project finder'),
        ),
        _ActivityShortcut(
          icon: Icons.school_outlined,
          title: 'Explore mentorship opportunities',
          subtitle: 'Open mentorship',
          accent: const Color(0xFFF7BA59),
          onTap: () => onFeature('Mentorship'),
        ),
      ],
    ),
  );

  Widget _terminalPanel(BuildContext context) {
    final details = profile?.editable;
    final role = profile?.role.toLowerCase() ?? 'loading';
    final programme = profile?.academicLabel ?? 'loading';
    final skills = (details?['skills'] as List?)?.length;
    final lines = [
      '// Your UniConnect profile',
      'role: "$role",',
      'programme: "$programme",',
      'skills: ${skills ?? 'loading'},',
      'status: "active"',
      '}',
    ];
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TerminalBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(27, 17, 24, 20),
                child: Column(
                  children: [
                    for (var index = 0; index < lines.length; index++)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Color(0xFFA57B8C)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              lines[index],
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                height: 1.85,
                                color: index == 0 || index == lines.length - 1
                                    ? const Color(0xFFF7DB51)
                                    : AppTheme.engineeringText,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(right: 15, bottom: 12, child: _TerminalDetail()),
        ],
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required String title,
    required Widget child,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 300),
    padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
    decoration: _panelDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(height: 20),
        child,
      ],
    ),
  );

  BoxDecoration _panelDecoration() => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF2300B1E), Color(0xE9210913)],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFBD3466)),
    boxShadow: const [
      BoxShadow(color: Color(0x33090206), blurRadius: 30, offset: Offset(0, 7)),
    ],
  );
}

class _EngineeringFeatureCard extends StatefulWidget {
  const _EngineeringFeatureCard({
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
  State<_EngineeringFeatureCard> createState() =>
      _EngineeringFeatureCardState();
}

class _EngineeringFeatureCardState extends State<_EngineeringFeatureCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        constraints: const BoxConstraints(minHeight: 166),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 140),
        transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hovered
                ? const [Color(0xFF4A122B), Color(0xFF2D0C1A)]
                : const [Color(0xEE390D20), Color(0xF0230B17)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hovered ? const Color(0xFFFF6297) : const Color(0xFFCD396B),
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: AppTheme.engineeringAccent.withValues(alpha: .18),
                    blurRadius: 18,
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    widget.icon,
                    color: AppTheme.engineeringAccent,
                    size: 52,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.subtitle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityShortcut extends StatelessWidget {
  const _ActivityShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AppTheme.engineeringAccent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x5075213C))),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFCBA0B0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(radius: 4.5, backgroundColor: Color(0xFFEC79A1)),
          ],
        ),
      ),
    ),
  );
}

class _TerminalBar extends StatelessWidget {
  const _TerminalBar();

  @override
  Widget build(BuildContext context) => Container(
    height: 51,
    padding: const EdgeInsets.symmetric(horizontal: 19),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF85334D))),
    ),
    child: const Row(
      children: [
        _TerminalDot(Color(0xFFFF5D62)),
        SizedBox(width: 8),
        _TerminalDot(Color(0xFFFFC247)),
        SizedBox(width: 8),
        _TerminalDot(Color(0xFF40CA76)),
      ],
    ),
  );
}

class _TerminalDot extends StatelessWidget {
  const _TerminalDot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) =>
      CircleAvatar(radius: 6.5, backgroundColor: color);
}

class _TerminalDetail extends StatelessWidget {
  const _TerminalDetail();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 113,
    height: 16,
    child: CustomPaint(painter: _TerminalDetailPainter()),
  );
}

class _TerminalDetailPainter extends CustomPainter {
  const _TerminalDetailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF24884)
      ..style = PaintingStyle.fill;
    for (double x = 8; x < size.width; x += 12) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo((x + 8).clamp(0, size.width), 0)
          ..lineTo((x + 2).clamp(0, size.width), size.height)
          ..lineTo((x - 6).clamp(0, size.width), size.height)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TerminalDetailPainter oldDelegate) => false;
}
