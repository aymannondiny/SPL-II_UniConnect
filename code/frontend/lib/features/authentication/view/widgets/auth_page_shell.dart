import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_hero.dart';

/// Responsive authentication chrome shared by signup and verification.
class AuthPageShell extends StatefulWidget {
  const AuthPageShell({required this.child, this.header, super.key});

  final Widget child;
  final Widget? header;

  @override
  State<AuthPageShell> createState() => _AuthPageShellState();
}

class _AuthPageShellState extends State<AuthPageShell> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final dark = _themeMode == ThemeMode.system
        ? Theme.of(context).brightness == Brightness.dark
        : _themeMode == ThemeMode.dark;
    return Theme(
      data: dark ? AppTheme.dark() : AppTheme.light(),
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
                        IconButton(
                          tooltip: dark
                              ? 'Switch to light theme'
                              : 'Switch to dark theme',
                          onPressed: () => setState(
                            () => _themeMode = dark
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          ),
                          icon: Icon(
                            dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                    ? Column(children: [const AuthHero(compact: true), panel])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: AuthHero(compact: false)),
                          Expanded(child: panel),
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
