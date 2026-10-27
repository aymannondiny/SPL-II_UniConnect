import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/app_theme.dart';

/// Lightweight projected geometry, drawn locally on every Flutter platform.
class CampusScene extends StatefulWidget {
  const CampusScene({super.key});

  @override
  State<CampusScene> createState() => _CampusSceneState();
}

class _CampusSceneState extends State<CampusScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  final ValueNotifier<double> _angle = ValueNotifier(-.55);
  bool _playing = false;
  bool? _evening;
  double _previous = 0;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _motion =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..addListener(() {
            final delta = (_motion.value - _previous + 1) % 1;
            _previous = _motion.value;
            _angle.value += delta * math.pi * 2;
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      _motion.stop();
      _playing = false;
    }
    if (!_entered) {
      _entered = true;
      if (!reducedMotion) {
        _motion.animateTo(.04, duration: const Duration(milliseconds: 900));
      }
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _angle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evening = _evening ?? Theme.of(context).brightness == Brightness.dark;
    final engineering = EngineeringTheme.active(context);
    return Column(
      children: [
        Semantics(
          label:
              'Interactive IUT campus with five brick gateway frames, a pond, '
              'palms and academic buildings. Drag horizontally to rotate.',
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              _motion.stop();
              setState(() => _playing = false);
            },
            onHorizontalDragUpdate: (details) {
              _angle.value -= details.delta.dx * .008;
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: SizedBox(
                height: 290,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (engineering)
                      const IgnorePointer(
                        child: CustomPaint(
                          key: Key('engineering-campus-light-arc'),
                          painter: _CampusLightArcPainter(),
                        ),
                      ),
                    RepaintBoundary(
                      child: CustomPaint(
                        key: const ValueKey('iut-campus-scene'),
                        painter: _CampusPainter(
                          angle: _angle,
                          evening: evening,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              style: engineering
                  ? OutlinedButton.styleFrom(
                      backgroundColor: const Color(0x80240714),
                    )
                  : null,
              onPressed: () => setState(() => _evening = !evening),
              icon: Icon(
                evening ? Icons.light_mode_outlined : Icons.nightlight_outlined,
              ),
              label: Text(evening ? 'Daylight' : 'Evening'),
            ),
            OutlinedButton.icon(
              style: engineering
                  ? OutlinedButton.styleFrom(
                      backgroundColor: const Color(0x80240714),
                    )
                  : null,
              onPressed: () {
                setState(() => _playing = !_playing);
                if (_playing) {
                  _previous = _motion.value;
                  _motion.repeat();
                } else {
                  _motion.stop();
                }
              },
              icon: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(_playing ? 'Pause motion' : 'Play motion'),
            ),
            IconButton.outlined(
              style: engineering
                  ? IconButton.styleFrom(
                      backgroundColor: const Color(0x80240714),
                      foregroundColor: AppTheme.engineeringText,
                      side: const BorderSide(color: AppTheme.engineeringAccent),
                    )
                  : null,
              tooltip: 'Rotate campus',
              onPressed: () => _angle.value += .45,
              icon: const Icon(Icons.rotate_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Drag to look around · A little IUT, a lot of possibility',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CampusLightArcPainter extends CustomPainter {
  const _CampusLightArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .72),
      width: size.width * .78,
      height: size.height * .35,
    );
    final glow = Paint()
      ..color = AppTheme.engineeringAccent.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final line = Paint()
      ..color = AppTheme.engineeringSoftPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    const start = .12;
    const sweep = math.pi * .76;
    canvas.drawArc(rect, start, sweep, false, glow);
    canvas.drawArc(rect, start, sweep, false, line);
  }

  @override
  bool shouldRepaint(_CampusLightArcPainter oldDelegate) => false;
}

class _Point {
  const _Point(this.x, this.y, this.z);
  final double x, y, z;
}

class _Face {
  const _Face(this.points, this.color);
  final List<_Point> points;
  final Color color;
}

class _CampusPainter extends CustomPainter {
  _CampusPainter({required this.angle, required this.evening})
    : super(repaint: angle);
  final ValueNotifier<double> angle;
  final bool evening;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 540, size.height / 350);
    final origin = Offset(size.width / 2, size.height * .65);
    final sin = math.sin(angle.value), cos = math.cos(angle.value);
    Offset project(_Point p) =>
        origin +
        Offset(
          (p.x * cos - p.z * sin) * scale,
          ((p.x * sin + p.z * cos) * .43 - p.y) * scale,
        );
    final faces = <_Face>[];
    void renderFace(_Face face) {
      final path = Path();
      for (int i = 0; i < face.points.length; i++) {
        final p = project(face.points[i]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path..close(), Paint()..color = face.color);
    }

    void polygon(List<_Point> points, Color color) =>
        faces.add(_Face(points, color));
    void box(
      double x,
      double z,
      double w,
      double d,
      double h,
      Color top,
      Color front,
      Color side, [
      double y = 0,
    ]) {
      polygon([
        _Point(x, y, z),
        _Point(x + w, y, z),
        _Point(x + w, y + h, z),
        _Point(x, y + h, z),
      ], front);
      polygon([
        _Point(x + w, y, z),
        _Point(x + w, y, z + d),
        _Point(x + w, y + h, z + d),
        _Point(x + w, y + h, z),
      ], side);
      polygon([
        _Point(x, y, z + d),
        _Point(x + w, y, z + d),
        _Point(x + w, y + h, z + d),
        _Point(x, y + h, z + d),
      ], side);
      polygon([
        _Point(x, y, z),
        _Point(x, y, z + d),
        _Point(x, y + h, z + d),
        _Point(x, y + h, z),
      ], front);
      polygon([
        _Point(x, y + h, z),
        _Point(x + w, y + h, z),
        _Point(x + w, y + h, z + d),
        _Point(x, y + h, z + d),
      ], top);
    }

    final grass = Color(evening ? 0xFF36584B : 0xFFABC88B);
    final brick = Color(evening ? 0xFF773B36 : 0xFFB85D49);
    final top = Color(evening ? 0xFF985548 : 0xFFD98567);
    final side = Color(evening ? 0xFF512D2B : 0xFF8E4436);
    canvas.drawOval(
      Rect.fromCenter(
        center: origin + Offset(0, 72 * scale),
        width: 455 * scale,
        height: 80 * scale,
      ),
      Paint()..color = grass.withValues(alpha: .18),
    );
    box(
      -220,
      -145,
      440,
      290,
      16,
      grass,
      grass.withValues(alpha: .9),
      side,
      -19,
    );
    polygon([
      const _Point(-185, 0, -20),
      const _Point(35, 0, -20),
      const _Point(35, 0, 115),
      const _Point(-185, 0, 115),
    ], Color(evening ? 0xFF244E61 : 0xFF69B0AD));
    polygon([
      const _Point(45, 1, -140),
      const _Point(72, 1, -140),
      const _Point(72, 1, 135),
      const _Point(45, 1, 135),
    ], const Color(0xFFD6B299));
    // Ground and water must remain beneath every elevated surface.
    for (final face in faces) {
      renderFace(face);
    }
    faces.clear();
    for (double x = -175; x < 170; x += 105) {
      box(x, -125, 78, 45, 64, top, brick, side);
      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 3; j++) {
          box(
            x + 7 + i * 13,
            -126,
            6,
            1,
            10,
            side,
            Color(evening ? 0xFFD9B475 : 0xFF633F3B),
            side,
            12 + j * 16.0,
          );
        }
      }
    }
    box(-200, -50, 90, 27, 34, top, brick, side);
    box(90, -35, 90, 37, 42, top, brick, side);
    for (int i = 0; i < 6; i++) {
      box(94 + i * 14.0, -36, 7, 1, 16, top, side, side, 4);
    }
    // Five solid rectangular frames with a clear pointed opening through them.
    for (int k = 0; k < 5; k++) {
      final x = -97 + k * 2.0,
          z = 56 - k * 15.0,
          w = 116 - k * 4.0,
          h = 176 - k * 5.0;
      final c = x + w / 2,
          half = 27 - k * 1.4,
          spring = 94 - k * 3.0,
          peak = h - 27;
      final left = <Offset>[
        Offset(x, 0),
        Offset(c - half, 0),
        Offset(c - half, spring),
        Offset(c - half * .78, spring + 17),
        Offset(c - half * .38, peak - 8),
        Offset(c, peak),
        Offset(c, h),
        Offset(x, h),
      ];
      final right = left
          .map((p) => Offset(2 * c - p.dx, p.dy))
          .toList()
          .reversed
          .toList();
      for (final outline in [left, right]) {
        polygon(outline.map((p) => _Point(p.dx, p.dy, z)).toList(), brick);
        polygon(outline.map((p) => _Point(p.dx, p.dy, z + 6)).toList(), side);
        for (int i = 0; i < outline.length; i++) {
          final a = outline[i], b = outline[(i + 1) % outline.length];
          polygon([
            _Point(a.dx, a.dy, z),
            _Point(b.dx, b.dy, z),
            _Point(b.dx, b.dy, z + 6),
            _Point(a.dx, a.dy, z + 6),
          ], a.dy == b.dy ? top : side);
        }
      }
    }
    for (double x = -185; x < 200; x += 43) {
      const z = 123.0;
      box(x, z, 3, 3, 37, top, const Color(0xFF8F6C4B), side);
      for (int k = 0; k < 6; k++) {
        final a = k * math.pi / 3;
        polygon([
          _Point(x, 38, z),
          _Point(x + math.cos(a) * 24, 30, z + math.sin(a) * 24),
          _Point(x + math.cos(a + .4) * 15, 37, z + math.sin(a + .4) * 15),
        ], Color(evening ? 0xFF426E57 : 0xFF59875A));
      }
    }
    // Sort all surfaces, including the gateway recesses, as the camera turns.
    double depth(_Face face) =>
        face.points.fold<double>(0, (v, p) => v + p.x * sin + p.z * cos) /
        face.points.length;
    faces.sort((a, b) => depth(a).compareTo(depth(b)));
    for (final face in faces) {
      renderFace(face);
    }
  }

  @override
  bool shouldRepaint(_CampusPainter oldDelegate) =>
      oldDelegate.evening != evening || oldDelegate.angle != angle;
}
