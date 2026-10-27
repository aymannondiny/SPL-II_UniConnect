import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/authentication/view/widgets/brand_mark.dart';
import 'package:uniconnect/features/authentication/view/widgets/campus_scene.dart';

class AuthHero extends StatelessWidget {
  const AuthHero({required this.compact, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final engineering = EngineeringTheme.active(context);
    final ink = engineering
        ? AppTheme.engineeringText
        : Color(dark ? 0xFFE5F1E8 : 0xFF25382F);
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
            if (engineering)
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Your campus.\nYour kind of '),
                    TextSpan(
                      text: 'people.',
                      style: TextStyle(color: AppTheme.engineeringAccent),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: compact ? 30 : 40,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              )
            else
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
            if (engineering) ...[
              const SizedBox(height: 14),
              Container(
                width: 76,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.engineeringAccent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const CampusScene(key: ValueKey('auth-campus')),
            if (engineering && !compact)
              const SizedBox(
                height: 72,
                width: 250,
                child: IgnorePointer(
                  child: CustomPaint(painter: _AuthCampusSilhouettePainter()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuthCampusSilhouettePainter extends CustomPainter {
  const _AuthCampusSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.engineeringAccent.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(0, size.height - 2)
      ..lineTo(size.width, size.height - 2)
      ..moveTo(18, size.height - 2)
      ..lineTo(18, 35)
      ..lineTo(55, 18)
      ..lineTo(92, 35)
      ..lineTo(92, size.height - 2)
      ..moveTo(37, size.height - 2)
      ..lineTo(37, 45)
      ..quadraticBezierTo(55, 17, 73, 45)
      ..lineTo(73, size.height - 2)
      ..moveTo(118, size.height - 2)
      ..lineTo(118, 42)
      ..lineTo(160, 28)
      ..lineTo(160, size.height - 2)
      ..moveTo(178, size.height - 2)
      ..lineTo(178, 48)
      ..lineTo(221, 35)
      ..lineTo(221, size.height - 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AuthCampusSilhouettePainter oldDelegate) => false;
}
