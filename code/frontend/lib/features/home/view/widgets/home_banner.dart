import 'package:flutter/material.dart';
import 'package:uniconnect/features/home/view/widgets/banner_arches.dart';
import 'package:uniconnect/features/home/view/widgets/home_summary_tiles.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({
    required this.name,
    required this.onFeature,
    this.alumni = false,
    super.key,
  });
  final String name;
  final bool alumni;
  final ValueChanged<String> onFeature;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF075438), Color(0xFF013220)]
              : const [Color(0xFF8F2236), Color(0xFF561220)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: const BannerArches(),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 24 : 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$greeting, ${name.trim().split(RegExp(r'\s+')).first}.',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: MediaQuery.sizeOf(context).width >= 900 ? 40 : 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                alumni
                    ? 'Share your experience. Connect with your community.'
                    : 'Your campus. Your people. Your next possibility.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFF2E5DE),
                ),
              ),
              const SizedBox(height: 28),
              HomeSummaryTiles(onFeature: onFeature, alumni: alumni),
            ],
          ),
        ),
      ),
    );
  }
}
