import 'package:flutter/material.dart';

/// Uses the same typography and chip treatment as the registration form.
class AuthFormHeading extends StatelessWidget {
  const AuthFormHeading({
    required this.badge,
    required this.title,
    required this.subtitle,
    super.key,
  });
  final String badge;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            label: Text(badge),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: .1),
            side: BorderSide.none,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle),
        const SizedBox(height: 28),
      ],
    );
  }
}
