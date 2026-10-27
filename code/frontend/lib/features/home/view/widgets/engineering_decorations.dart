import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';

/// Compact, native recreation of the shield-like UniConnect mark used by the
/// Engineering Mode reference. It intentionally remains vector-based so it is
/// crisp at different display scales without adding another raster asset.
class EngineeringBrandMark extends StatelessWidget {
  const EngineeringBrandMark({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 40,
    child: CustomPaint(painter: _EngineeringBrandMarkPainter()),
  );
}

class _EngineeringBrandMarkPainter extends CustomPainter {
  const _EngineeringBrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()
      ..color = AppTheme.engineeringText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final outer = Path()
      ..moveTo(5.5, 5)
      ..lineTo(5.5, 23)
      ..quadraticBezierTo(5.5, 29, 20, 36)
      ..quadraticBezierTo(34.5, 29, 34.5, 23)
      ..lineTo(34.5, 5);
    final inner = Path()
      ..moveTo(12, 7)
      ..lineTo(12, 21.5)
      ..quadraticBezierTo(12, 25.5, 20, 29.5)
      ..quadraticBezierTo(28, 25.5, 28, 21.5)
      ..lineTo(28, 7);
    canvas.drawPath(outer, stroke);
    canvas.drawPath(inner, stroke);
    canvas.drawCircle(
      const Offset(20, 8),
      1.8,
      Paint()..color = AppTheme.engineeringText,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EngineeringBrandMarkPainter oldDelegate) => false;
}

class EngineeringBackdrop extends StatelessWidget {
  const EngineeringBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF17050C), Color(0xFF280512), Color(0xFF14070E)],
        stops: [0, .65, 1],
      ),
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(child: CustomPaint(painter: CircuitPainter())),
          ),
        ),
        child,
      ],
    ),
  );
}

class CircuitPainter extends CustomPainter {
  const CircuitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          const RadialGradient(colors: [Color(0x99490D28), Color(0x00490D28)])
              .createShader(
                Rect.fromCircle(
                  center: Offset(size.width * .68, size.height * .21),
                  radius: size.width * .48,
                ),
              );
    canvas.drawRect(Offset.zero & size, glow);

    final grid = Paint()
      ..color = const Color(0x12FF4A85)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 75) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 75) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    canvas.save();
    canvas.scale(size.width / 1400, size.height / 880);
    final trace = Paint()
      ..color = const Color(0x8CF33A78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final paths = <Path>[
      Path()
        ..moveTo(8, 295)
        ..lineTo(65, 295)
        ..lineTo(95, 263)
        ..lineTo(330, 263)
        ..lineTo(345, 278)
        ..lineTo(485, 278),
      Path()
        ..moveTo(2, 338)
        ..lineTo(45, 338)
        ..lineTo(85, 298)
        ..lineTo(266, 298)
        ..lineTo(288, 318)
        ..lineTo(570, 318),
      Path()
        ..moveTo(600, 62)
        ..lineTo(815, 62)
        ..lineTo(860, 22)
        ..lineTo(1025, 22)
        ..lineTo(1053, 48)
        ..lineTo(1260, 48),
      Path()
        ..moveTo(780, 125)
        ..lineTo(988, 125)
        ..lineTo(1032, 83)
        ..lineTo(1190, 83),
      Path()
        ..moveTo(1000, 720)
        ..lineTo(1140, 720)
        ..lineTo(1200, 660)
        ..lineTo(1400, 660),
      Path()
        ..moveTo(760, 752)
        ..lineTo(1100, 752)
        ..lineTo(1144, 710)
        ..lineTo(1400, 710),
      Path()
        ..moveTo(20, 750)
        ..lineTo(180, 750)
        ..lineTo(210, 720)
        ..lineTo(575, 720),
    ];
    for (final path in paths) {
      canvas.drawPath(path, trace);
    }
    final junction = Paint()..color = const Color(0xCCF33A78);
    for (final point in const [
      Offset(95, 263),
      Offset(345, 278),
      Offset(860, 22),
      Offset(1032, 83),
      Offset(1200, 660),
      Offset(210, 720),
    ]) {
      canvas.drawCircle(point, 3, junction);
    }
    _paintTower(canvas);
    canvas.restore();
  }

  void _paintTower(Canvas canvas) {
    final tower = Paint()
      ..color = const Color(0xD1EE2F70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.save();
    canvas.translate(1250, 620);
    final path = Path()
      ..moveTo(70, 8)
      ..lineTo(17, 230)
      ..lineTo(123, 230)
      ..close()
      ..moveTo(38, 140)
      ..lineTo(102, 140)
      ..moveTo(28, 182)
      ..lineTo(112, 182)
      ..moveTo(48, 97)
      ..lineTo(92, 97)
      ..moveTo(58, 56)
      ..lineTo(82, 56)
      ..moveTo(17, 230)
      ..lineTo(102, 140)
      ..lineTo(48, 97)
      ..lineTo(82, 56)
      ..moveTo(123, 230)
      ..lineTo(38, 140)
      ..lineTo(92, 97)
      ..lineTo(58, 56)
      ..moveTo(4, 95)
      ..lineTo(136, 95)
      ..moveTo(15, 125)
      ..lineTo(125, 125);
    canvas.drawPath(path, tower);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CircuitPainter oldDelegate) => false;
}

class EngineeringSidebarBlueprint extends StatelessWidget {
  const EngineeringSidebarBlueprint({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 235,
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF220712), Color(0xFF390C21), Color(0xFF210713)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFA02C55)),
    ),
    child: const Stack(
      children: [
        Positioned(
          left: -10,
          right: -10,
          top: 8,
          height: 122,
          child: CustomPaint(painter: CampusBlueprintPainter()),
        ),
        Positioned(
          left: 16,
          bottom: 18,
          child: Text(
            'IUT\nIDEAS\nPEOPLE\nIMPACT',
            style: TextStyle(
              color: AppTheme.engineeringText,
              fontSize: 12,
              height: 1.45,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 29,
          width: 49,
          height: 4,
          child: ColoredBox(color: AppTheme.engineeringAccent),
        ),
      ],
    ),
  );
}

class CampusBlueprintPainter extends CustomPainter {
  const CampusBlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 640, size.height / 250);
    final paint = Paint()
      ..color = AppTheme.engineeringAccent.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.7;
    final structure = Path()
      ..moveTo(0, 226)
      ..lineTo(640, 226)
      ..moveTo(45, 210)
      ..lineTo(180, 210)
      ..lineTo(180, 142)
      ..lineTo(220, 118)
      ..lineTo(220, 210)
      ..lineTo(270, 210)
      ..lineTo(270, 70)
      ..lineTo(314, 51)
      ..lineTo(314, 210)
      ..lineTo(336, 210)
      ..lineTo(336, 40)
      ..lineTo(394, 18)
      ..lineTo(394, 210)
      ..lineTo(618, 210)
      ..lineTo(618, 156)
      ..lineTo(640, 156)
      ..moveTo(270, 70)
      ..lineTo(314, 51)
      ..lineTo(336, 40)
      ..lineTo(394, 18)
      ..lineTo(455, 43)
      ..lineTo(455, 210)
      ..moveTo(394, 18)
      ..lineTo(394, 210)
      ..moveTo(220, 118)
      ..lineTo(270, 134)
      ..moveTo(180, 142)
      ..lineTo(220, 162)
      ..lineTo(220, 210)
      ..moveTo(270, 134)
      ..lineTo(270, 210)
      ..moveTo(0, 216)
      ..lineTo(640, 216)
      ..moveTo(45, 210)
      ..lineTo(45, 194)
      ..lineTo(180, 194);
    canvas.drawPath(structure, paint);
    for (final arch in const [
      (394.0, 72.0, 448.0, 190.0),
      (336.0, 90.0, 387.0, 190.0),
      (485.0, 123.0, 530.0, 210.0),
      (540.0, 123.0, 585.0, 210.0),
      (591.0, 123.0, 634.0, 210.0),
    ]) {
      final archPath = Path()
        ..moveTo(arch.$1, arch.$4)
        ..lineTo(arch.$1, arch.$2)
        ..quadraticBezierTo(
          (arch.$1 + arch.$3) / 2,
          arch.$2 - 42,
          arch.$3,
          arch.$2,
        )
        ..lineTo(arch.$3, arch.$4);
      canvas.drawPath(archPath, paint);
    }
    final detail = Paint()
      ..color = AppTheme.engineeringAccent.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final x in const [
      283.0,
      294.0,
      305.0,
      348.0,
      360.0,
      373.0,
      407.0,
      419.0,
      431.0,
      443.0,
    ]) {
      canvas.drawLine(Offset(x, x < 320 ? 57 : 35), Offset(x, 210), detail);
    }
    for (final y in const [114.0, 164.0, 193.0]) {
      canvas.drawLine(Offset(272, y), Offset(454, y), detail);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CampusBlueprintPainter oldDelegate) => false;
}

class ChipPainter extends CustomPainter {
  const ChipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 100;
    canvas.save();
    canvas.scale(sx, sy);
    final paint = Paint()
      ..color = AppTheme.engineeringAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(25, 25, 50, 50),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 35, 30, 30),
        const Radius.circular(2),
      ),
      paint,
    );
    for (final value in const [35.0, 50.0, 65.0]) {
      canvas.drawLine(Offset(value, 12), Offset(value, 25), paint);
      canvas.drawLine(Offset(value, 75), Offset(value, 88), paint);
      canvas.drawLine(Offset(12, value), Offset(25, value), paint);
      canvas.drawLine(Offset(75, value), Offset(88, value), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChipPainter oldDelegate) => false;
}
