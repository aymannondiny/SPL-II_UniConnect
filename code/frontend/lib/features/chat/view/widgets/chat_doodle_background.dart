import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A fixed, decorative wallpaper; scrolling messages repaint independently.
class ChatDoodleBackground extends StatelessWidget {
  const ChatDoodleBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _CampusDoodlesPainter(
                    background:
                        theme.appBarTheme.backgroundColor ?? colors.surface,
                    ink: (dark ? colors.onSurfaceVariant : colors.primary)
                        .withValues(alpha: .29),
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CampusDoodlesPainter extends CustomPainter {
  const _CampusDoodlesPainter({required this.background, required this.ink});

  final Color background;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(background, BlendMode.src);
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const angles = [-.26, .18, -.12, .3, .1, -.32, .22];
    for (var row = 0; row * 92 < size.height + 92; row++) {
      for (var column = -1; column * 96 < size.width + 96; column++) {
        final index = row * 7 + column + 1;
        canvas.save();
        canvas.translate(
          column * 96 + 48 + (row.isOdd ? 38 : 0),
          row * 92 + 42,
        );
        canvas.rotate(angles[index % angles.length]);
        final scale = .78 + (index % 4) * .06;
        canvas.scale(scale);
        canvas.translate(-32, -32);
        _drawDoodle(canvas, pen, index % 12);
        canvas.drawCircle(const Offset(65, 5), 2.5, pen);
        if (index.isEven) {
          canvas.drawLine(const Offset(4, 65), const Offset(11, 61), pen);
          canvas.drawLine(const Offset(9, 70), const Offset(16, 66), pen);
        }
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void _drawDoodle(Canvas canvas, Paint pen, int motif) {
    void path(List<Offset> points, {bool close = false}) {
      final outline = Path()..addPolygon(points, close);
      canvas.drawPath(outline, pen);
    }

    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pen);

    void box(
      double left,
      double top,
      double right,
      double bottom, [
      double radius = 3,
    ]) => canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        Radius.circular(radius),
      ),
      pen,
    );

    switch (motif) {
      case 0: // Open book.
        canvas.drawPath(
          Path()
            ..moveTo(32, 16)
            ..quadraticBezierTo(20, 8, 6, 14)
            ..lineTo(6, 49)
            ..quadraticBezierTo(20, 43, 32, 51)
            ..quadraticBezierTo(44, 43, 58, 49)
            ..lineTo(58, 14)
            ..quadraticBezierTo(44, 8, 32, 16)
            ..lineTo(32, 51),
          pen,
        );
      case 1: // Graduation cap.
        path(const [
          Offset(3, 23),
          Offset(31, 11),
          Offset(61, 23),
          Offset(31, 36),
        ], close: true);
        canvas.drawPath(
          Path()
            ..moveTo(14, 29)
            ..lineTo(14, 43)
            ..quadraticBezierTo(31, 55, 49, 43)
            ..lineTo(49, 29),
          pen,
        );
        line(59, 24, 59, 47);
        line(56, 49, 62, 49);
      case 2: // Coffee.
        canvas.drawPath(
          Path()
            ..moveTo(10, 22)
            ..lineTo(47, 22)
            ..lineTo(44, 45)
            ..quadraticBezierTo(29, 58, 14, 45)
            ..close(),
          pen,
        );
        canvas.drawArc(
          const Rect.fromLTWH(42, 26, 17, 17),
          -math.pi / 2,
          math.pi,
          false,
          pen,
        );
        line(8, 56, 51, 56);
        for (final x in [19.0, 29.0, 39.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(x, 15)
              ..quadraticBezierTo(x - 5, 10, x, 5),
            pen,
          );
        }
      case 3: // Atom.
        for (var orbit = 0; orbit < 3; orbit++) {
          canvas.save();
          canvas.translate(32, 32);
          canvas.rotate(orbit * math.pi / 3);
          canvas.drawOval(const Rect.fromLTWH(-29, -11, 58, 22), pen);
          canvas.restore();
        }
        canvas.drawCircle(const Offset(32, 32), 3, pen);
      case 4: // Pencil.
        path(const [
          Offset(10, 45),
          Offset(44, 11),
          Offset(54, 21),
          Offset(20, 55),
          Offset(7, 58),
        ], close: true);
        line(38, 17, 48, 27);
        line(10, 45, 20, 55);
        line(19, 44, 41, 22);
      case 5: // Light bulb.
        canvas.drawPath(
          Path()
            ..moveTo(23, 44)
            ..lineTo(23, 39)
            ..cubicTo(3, 23, 17, 5, 32, 7)
            ..cubicTo(50, 5, 60, 25, 41, 39)
            ..lineTo(41, 44)
            ..close(),
          pen,
        );
        line(24, 50, 40, 50);
        line(27, 56, 37, 56);
        line(32, 43, 32, 30);
        path(const [Offset(26, 26), Offset(32, 31), Offset(38, 26)]);
      case 6: // Headphones.
        canvas.drawArc(
          const Rect.fromLTWH(9, 8, 46, 48),
          math.pi,
          math.pi,
          false,
          pen,
        );
        box(7, 31, 19, 52, 5);
        box(45, 31, 57, 52, 5);
      case 7: // Chemistry flask.
        path(const [
          Offset(23, 8),
          Offset(41, 8),
          Offset(41, 12),
          Offset(38, 12),
          Offset(38, 28),
          Offset(56, 53),
          Offset(54, 57),
          Offset(10, 57),
          Offset(8, 53),
          Offset(26, 28),
          Offset(26, 12),
          Offset(23, 12),
        ], close: true);
        line(18, 42, 46, 42);
        canvas.drawCircle(const Offset(30, 48), 2, pen);
        canvas.drawCircle(const Offset(36, 35), 2, pen);
      case 8: // Calculator.
        box(13, 5, 51, 59, 5);
        box(20, 13, 44, 25, 1);
        for (final y in [34.0, 43.0, 52.0]) {
          for (final x in [22.0, 32.0, 42.0]) {
            line(x - 1, y, x + 1, y);
          }
        }
      case 9: // Laptop.
        box(12, 10, 52, 42);
        path(const [
          Offset(12, 42),
          Offset(4, 53),
          Offset(60, 53),
          Offset(52, 42),
        ]);
        line(4, 53, 8, 57);
        line(8, 57, 56, 57);
        line(56, 57, 60, 53);
        line(26, 48, 38, 48);
      case 10: // Spiral notebook.
        box(16, 7, 53, 57);
        for (final y in [15.0, 25.0, 35.0, 45.0]) {
          line(10, y, 22, y);
          line(29, y + 3, 44, y + 3);
        }
      case 11: // Star and code brackets.
        final points = List.generate(10, (i) {
          final angle = i * math.pi / 5 - math.pi / 2;
          final radius = i.isEven ? 23 : 11;
          return Offset(
            32 + math.cos(angle) * radius,
            32 + math.sin(angle) * radius,
          );
        });
        path(points, close: true);
    }
  }

  @override
  bool shouldRepaint(_CampusDoodlesPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.ink != ink;
}
