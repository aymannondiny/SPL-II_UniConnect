import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/core/theme/appearance_menu_button.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_hero.dart';

/// Responsive authentication chrome shared by all authentication pages.
class AuthPageShell extends StatefulWidget {
  const AuthPageShell({required this.child, this.header, super.key});

  final Widget child;
  final Widget? header;

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
    return Theme(
      data: theme,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              final panel = Padding(
                padding: EdgeInsets.all(compact ? 16 : 40),
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
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 24 : 36),
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
                                            ? const [
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
                              const Expanded(child: AuthHero(compact: false)),
                              Expanded(child: panel),
                            ],
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
