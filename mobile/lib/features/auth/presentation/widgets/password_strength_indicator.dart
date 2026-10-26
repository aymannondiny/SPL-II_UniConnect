import 'package:flutter/material.dart';

import '../../../../core/utils/password_policy.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({required this.controller, super.key});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final score = PasswordPolicy.strength(value.text);
          final scheme = Theme.of(context).colorScheme;
          final label = [
            'Enter a password',
            'Weak',
            'Fair',
            'Good',
            'Strong',
          ][score];
          final color = score == 1 ? scheme.error : scheme.primary;
          return Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: score / 4, color: color),
                  const SizedBox(height: 8),
                  Text('Password strength: $label'),
                ],
              ),
            ),
          );
        },
      );
}
