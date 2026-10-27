import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps the decorative edge ribbons fixed while messages scroll above them.
class ChatRibbonBackground extends StatelessWidget {
  const ChatRibbonBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _RibbonEdgePainter(
                    background:
                        theme.appBarTheme.backgroundColor ?? colors.surface,
                    ink: colors.primary.withValues(alpha: .18),
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

class _RibbonEdgePainter extends CustomPainter {
  const _RibbonEdgePainter({required this.background, required this.ink});

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
      ..strokeWidth = 1;

    void ribbon(Offset center, Size bounds, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: bounds.width,
        height: bounds.height,
      );
      for (var i = 0; i < 4; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(i * 20),
            Radius.circular(bounds.width * .46 + i * 20),
          ),
          pen,
        );
      }
      canvas.restore();
    }

    final height = size.height.clamp(340.0, 540.0);
    ribbon(
      Offset(size.width + 37, height * .45),
      Size(210, height),
      28 * math.pi / 180,
    );
    ribbon(
      Offset(-105, size.height - 45),
      const Size(155, 380),
      35 * math.pi / 180,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RibbonEdgePainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.ink != ink;
}
