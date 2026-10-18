import 'package:flutter/material.dart';

/// A rounded arch with vertical stems, matching the reference SVG geometry.
class BannerArches extends CustomPainter {
  const BannerArches();
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width - 105;
    final springY = size.height - 38;
    final bottom = size.height + 60;
    var index = 0;
    for (final radius in [150.0, 106.0, 62.0]) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: [.07, .1, .14][index++])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22;
      final left = centerX - radius;
      final right = centerX + radius;
      final path = Path()
        ..moveTo(left, bottom)
        ..lineTo(left, springY)
        ..cubicTo(
          left,
          springY - radius * .5523,
          centerX - radius * .5523,
          springY - radius,
          centerX,
          springY - radius,
        )
        ..cubicTo(
          centerX + radius * .5523,
          springY - radius,
          right,
          springY - radius * .5523,
          right,
          springY,
        )
        ..lineTo(right, bottom);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BannerArches oldDelegate) => false;
}
