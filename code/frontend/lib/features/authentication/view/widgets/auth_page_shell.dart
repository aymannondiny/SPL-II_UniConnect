import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/appearance_menu_button.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_hero.dart';

/// Responsive authentication chrome shared by all authentication pages.
class AuthPageShell extends StatefulWidget {
  const AuthPageShell({
    required this.child,
    this.header,
    this.engineeringPresentation = false,
    super.key,
  });

  final Widget child;
  final Widget? header;
  final bool engineeringPresentation;

  @override
  State<AuthPageShell> createState() => _AuthPageShellState();
}

class _AuthPageShellState extends State<AuthPageShell> {
  AppearanceMode _appearance = AppearanceMode.dark;

  @override
  Widget build(BuildContext context) {
    final preference = ThemePreference.maybeOf(context);
    final mode = preference?.value ?? _appearance;
    final theme = switch (mode) {
      AppearanceMode.light => AppTheme.light(),
      AppearanceMode.dark => AppTheme.dark(),
      AppearanceMode.engineering => AppTheme.engineering(),
    };
    final dark = theme.brightness == Brightness.dark;
    final engineering =
        widget.engineeringPresentation && mode == AppearanceMode.engineering;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: engineering ? Colors.transparent : null,
        body: Stack(
          children: [
            Positioned.fill(
              child: engineering
                  ? const _EngineeringAuthBackdrop(
                      key: Key('engineering-login-shell'),
                    )
                  : const SizedBox.shrink(),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 900;
                  final panel = Padding(
                    padding: EdgeInsets.all(
                      compact
                          ? 16
                          : engineering
                          ? 52
                          : 40,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.header != null)
                              Flexible(child: widget.header!),
                            AppearanceMenuButton(
                              mode: mode,
                              onSelected: (next) {
                                if (preference != null) {
                                  preference.value = next;
                                } else {
                                  setState(() => _appearance = next);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (compact) ...[
                          const AuthHero(compact: true),
                          const SizedBox(height: 24),
                        ],
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: engineering ? 630 : 560,
                            ),
                            child: Card(
                              color: engineering
                                  ? const Color(0xE63A0A1F)
                                  : null,
                              elevation: engineering ? 12 : null,
                              shadowColor: engineering
                                  ? const Color(0x99000000)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  engineering ? 30 : 28,
                                ),
                                side: engineering
                                    ? const BorderSide(
                                        color: Color(0xFFFF7BA7),
                                        width: 1.2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  compact
                                      ? 24
                                      : engineering
                                      ? 54
                                      : 36,
                                ),
                                child: widget.child,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  return SingleChildScrollView(
                    child: compact
                        ? panel
                        : Stack(
                            children: [
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            radius: .9,
                                            colors: dark
                                                ? engineering
                                                      ? const [
                                                          Color(0xB5320718),
                                                          Color(0x00250713),
                                                        ]
                                                      : const [
                                                          Color(0xFF294D41),
                                                          Color(0xFF182A26),
                                                        ]
                                                : const [
                                                    Color(0xFFD4EBD9),
                                                    Color(0xFFFCFAF2),
                                                  ],
                                          ),
                                        ),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                    const Expanded(child: SizedBox()),
                                  ],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    child: AuthHero(compact: false),
                                  ),
                                  Expanded(child: panel),
                                ],
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineeringAuthBackdrop extends StatelessWidget {
  const _EngineeringAuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(-.12, -.12),
        radius: 1.2,
        colors: [Color(0xFF480A23), Color(0xFF240611), Color(0xFF13050B)],
      ),
    ),
    child: RepaintBoundary(
      child: IgnorePointer(child: CustomPaint(painter: _AuthCircuitPainter())),
    ),
  );
}

class _AuthCircuitPainter extends CustomPainter {
  const _AuthCircuitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x12FF4C87)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 68) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 68) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final trace = Paint()
      ..color = const Color(0x99EF326E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final paths = [
      Path()
        ..moveTo(size.width * .30, 72)
        ..lineTo(size.width * .39, 72)
        ..lineTo(size.width * .42, 38)
        ..lineTo(size.width * .50, 38),
      Path()
        ..moveTo(size.width * .30, size.height - 72)
        ..lineTo(size.width * .39, size.height - 72)
        ..lineTo(size.width * .42, size.height - 108)
        ..lineTo(size.width * .50, size.height - 108),
      Path()
        ..moveTo(size.width * .73, size.height - 48)
        ..lineTo(size.width * .83, size.height - 48)
        ..lineTo(size.width * .86, size.height - 84)
        ..lineTo(size.width, size.height - 84),
    ];
    for (final path in paths) {
      canvas.drawPath(path, trace);
    }
  }

  @override
  bool shouldRepaint(_AuthCircuitPainter oldDelegate) => false;
}
