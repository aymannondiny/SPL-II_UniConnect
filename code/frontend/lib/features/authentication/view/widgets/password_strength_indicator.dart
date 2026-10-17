import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/registration_validation.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final score = RegistrationValidation.strength(value.text);
        final scheme = Theme.of(context).colorScheme;
        final dark = scheme.brightness == Brightness.dark;
        final color = switch (score) {
          1 => scheme.error,
          2 || 3 => dark ? const Color(0xFFF6C85F) : const Color(0xFF87600B),
          4 => dark ? const Color(0xFF6FD8A8) : const Color(0xFF1F7A54),
          _ => scheme.onSurfaceVariant,
        };
        final label = switch (score) {
          0 => 'Password strength: enter a password',
          1 => 'Password strength: weak',
          2 => 'Password strength: fair',
          3 => 'Password strength: good',
          _ => 'Password strength: strong',
        };
        return Semantics(
          label: '$label. $score of 4. Strength is a suggestion only.',
          liveRegion: true,
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      key: ValueKey('password-strength-bar-$index'),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index < score ? color : scheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}
