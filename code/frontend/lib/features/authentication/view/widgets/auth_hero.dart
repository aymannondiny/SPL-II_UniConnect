import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/view/widgets/brand_mark.dart';
import 'package:uniconnect/features/authentication/view/widgets/campus_scene.dart';

class AuthHero extends StatelessWidget {
  const AuthHero({required this.compact, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Color(dark ? 0xFFE5F1E8 : 0xFF25382F);
    return Container(
      decoration: compact
          ? BoxDecoration(
              gradient: RadialGradient(
                radius: .9,
                colors: dark
                    ? const [Color(0xFF294D41), Color(0xFF182A26)]
                    : const [Color(0xFFD4EBD9), Color(0xFFFCFAF2)],
              ),
            )
          : null,
      padding: EdgeInsets.all(compact ? 24 : 40),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: ink),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BrandMark(dark: dark),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'UniConnect',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(dark ? 0xFF76A779 : 0xFF7E1D2E),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Your campus.\nYour kind of people.',
              style: TextStyle(
                fontSize: compact ? 30 : 40,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Meet classmates, discover communities, and make university feel a little more like home.',
            ),
            const SizedBox(height: 8),
            const CampusScene(),
          ],
        ),
      ),
    );
  }
}
