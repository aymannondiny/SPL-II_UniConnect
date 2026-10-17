import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/view/widgets/brand_mark.dart';

class AuthHero extends StatelessWidget {
  const AuthHero({required this.compact, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 280 : 760),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/auth/campus-${dark ? 'dark' : 'photo'}.jpg',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            (dark ? const Color(0xFF013220) : const Color(0xFF561220))
                .withValues(alpha: .55),
            BlendMode.srcOver,
          ),
        ),
      ),
      padding: EdgeInsets.all(compact ? 24 : 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              BrandMark(dark: dark),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'UniConnect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 28 : 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR CAMPUS, CONNECTED',
                  style: TextStyle(
                    color: Color(0xFFF6C85F),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Find your people.\nBuild your circle.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.08,
                    fontSize: compact ? 34 : 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Meet classmates, discover communities, and make university feel a little more like home.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!compact)
            const Text(
              'Students, alumni and clubs in one verified space.',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
        ],
      ),
    );
  }
}
