import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Efficiently paints the approved brick gateway in a fixed 1440 x 700
/// coordinate system. Only this canvas repaints while the animation runs.
class IutGatewayScene extends StatelessWidget {
  const IutGatewayScene({required this.progress, super.key});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'IUT brick gateway and four palm trees building beneath WELCOME',
    child: RepaintBoundary(
      child: CustomPaint(
        key: const Key('post-login-gateway-foreground'),
        painter: _IutGatewayPainter(progress),
        size: Size.infinite,
        isComplex: true,
        willChange: true,
      ),
    ),
  );
}

class _IutGatewayPainter extends CustomPainter {
  _IutGatewayPainter(this.progress) : super(repaint: progress);

  static const _sceneWidth = 1440.0;
  static const _sceneHeight = 700.0;
  static const _left = -220.0;
  static const _bottom = 608.0;
  static const _center = 500.0;
  static const _palette = <Color>[
    Color(0xffc76647),
    Color(0xffb95b40),
    Color(0xffd77750),
    Color(0xffb45339),
    Color(0xffcb6c48),
    Color(0xffa94a34),
  ];

  static final Path _masonryClip = _buildMasonryClip();
  static final List<_Brick> _masonry = _buildMasonry();
  static final List<_Wedge> _voussoirs = _buildVoussoirs();
  static final List<_PalmBlock> _palms = _buildPalms();
  static final List<_LetterBrick> _lettering = _buildLettering();

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.min(
      size.width / _sceneWidth,
      size.height / _sceneHeight,
    );
    final width = _sceneWidth * scale;
    final height = _sceneHeight * scale;
    canvas
      ..save()
      ..translate((size.width - width) / 2, (size.height - height) / 2)
      ..scale(scale)
      ..translate(-_left, 0);

    final total = _clamp01(progress.value);
    final gate = _clamp01(total / .81);
    final word = _clamp01((total - .81) / .19);

    _paintGround(canvas, gate);
    canvas
      ..save()
      ..clipPath(_masonryClip);
    for (final brick in _masonry) {
      final reveal = _reveal(gate, brick.delay, .87, .13);
      _paintRaisedPath(canvas, brick.path, brick.color, reveal, 85);
    }
    canvas.restore();

    for (final wedge in _voussoirs) {
      final reveal = _reveal(gate, wedge.delay, .87, .13);
      _paintRaisedPath(canvas, wedge.path, wedge.color, reveal, 85);
    }
    if (gate > .88) _paintInnerArch(canvas, _clamp01((gate - .88) / .12));

    final palmStage = _clamp01(gate * 1.08);
    for (final block in _palms) {
      final reveal = _clamp01((palmStage - block.delay) * 14);
      if (reveal <= 0) continue;
      final eased = _easeOutCubic(reveal);
      canvas.save();
      canvas.translate(0, (1 - eased) * -30);
      canvas.translate(block.center.dx, block.center.dy);
      canvas.rotate(block.rotation);
      final paint = Paint()..color = block.color.withValues(alpha: reveal);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: block.width,
            height: block.height,
          ),
          const Radius.circular(1.2),
        ),
        paint,
      );
      canvas.drawLine(
        Offset(-block.width * .32, -block.height * .25),
        Offset(block.width * .25, -block.height * .25),
        Paint()
          ..color = block.highlight.withValues(alpha: reveal * .55)
          ..strokeWidth = .8,
      );
      canvas.restore();
    }

    for (final brick in _lettering) {
      final reveal = _reveal(word, brick.delay, .83, .17);
      if (reveal <= 0) continue;
      final eased = _easeOutCubic(reveal);
      canvas.save();
      canvas.translate((1 - eased) * brick.xShift, (1 - eased) * -32);
      final rect = Rect.fromLTWH(brick.x, brick.y, 7.3, 7.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(.45)),
        Paint()..color = brick.color.withValues(alpha: reveal),
      );
      canvas.drawLine(
        rect.topLeft + const Offset(1.1, .7),
        rect.topRight + const Offset(-1.2, .7),
        Paint()
          ..color = const Color(0xffec9971).withValues(alpha: reveal)
          ..strokeWidth = .65,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  static void _paintGround(Canvas canvas, double opacity) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(_center, 650), width: 1300, height: 40),
      Paint()..color = const Color(0xff03050b).withValues(alpha: .38 * opacity),
    );
    canvas.drawLine(
      const Offset(-180, 624),
      const Offset(1180, 624),
      Paint()
        ..color = const Color(0xff8f4c38).withValues(alpha: .8 * opacity)
        ..strokeWidth = 2,
    );
  }

  static void _paintRaisedPath(
    Canvas canvas,
    Path path,
    Color color,
    double reveal,
    double travel,
  ) {
    if (reveal <= 0) return;
    final eased = _easeOutCubic(reveal);
    canvas
      ..save()
      ..translate(0, (1 - eased) * travel)
      ..drawPath(
        path,
        Paint()..color = color.withValues(alpha: math.min(1.0, reveal * 1.7)),
      )
      ..drawPath(
        path,
        Paint()
          ..color = const Color(0xff672b22).withValues(alpha: reveal)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();
  }

  static void _paintInnerArch(Canvas canvas, double opacity) {
    final path = Path();
    for (var index = 0; index <= 50; index++) {
      final point = _curve(-1, 127, 252, index / 50);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    for (var index = 50; index >= 0; index--) {
      final point = _curve(1, 127, 252, index / 50);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xffefab72).withValues(alpha: opacity * .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  static double _reveal(
    double stage,
    double delay,
    double spread,
    double rise,
  ) => _clamp01((stage - delay * spread) / rise);

  static double _clamp01(num value) => value.clamp(0.0, 1.0).toDouble();

  static double _easeOutCubic(double value) =>
      1 - math.pow(1 - value, 3).toDouble();

  static Offset _curve(int side, double span, double apex, double t) => Offset(
    (_center + side * span * math.pow(1 - t, .68)).toDouble(),
    _bottom - (_bottom - apex) * t,
  );

  static Path _pointedOpening(double span, double apex) {
    final path = Path();
    for (var index = 0; index <= 50; index++) {
      final point = _curve(-1, span, apex, index / 50);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    for (var index = 50; index >= 0; index--) {
      final point = _curve(1, span, apex, index / 50);
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static Path _arcadeOpening(double center) => Path()
    ..moveTo(center - 40, 615)
    ..lineTo(center - 40, 567)
    ..arcToPoint(
      Offset(center + 40, 567),
      radius: const Radius.circular(40),
      clockwise: true,
    )
    ..lineTo(center + 40, 615)
    ..close();

  static Path _buildMasonryClip() {
    final path = Path()..fillType = PathFillType.evenOdd;
    path
      ..addRect(const Rect.fromLTRB(285, 108, 715, 608))
      ..addRect(const Rect.fromLTRB(-145, 520, 285, 608))
      ..addRect(const Rect.fromLTRB(715, 520, 1145, 608))
      ..addPath(_pointedOpening(127, 252), Offset.zero);
    for (final center in const [
      -78.0,
      26.0,
      128.0,
      232.0,
      768.0,
      872.0,
      974.0,
      1078.0,
    ]) {
      path.addPath(_arcadeOpening(center), Offset.zero);
    }
    return path;
  }

  static List<_Brick> _buildMasonry() {
    final pieces = <_Brick>[];
    const width = 44.0;
    const height = 24.0;
    for (var row = 0; row < 22; row++) {
      final y = _bottom - (row + 1) * height;
      final shift = row.isOdd ? width / 2 : 0.0;
      for (var x = -175.0 - shift; x < 1190; x += width) {
        if (x + width < -145 || x > 1145) continue;
        final seed = (row * 19 + (x / 22).floor() + 600) % _palette.length;
        pieces.add(
          _Brick(
            Path()..addRect(Rect.fromLTWH(x, y, width, height)),
            _palette[seed],
            y,
            x,
          ),
        );
      }
    }
    pieces.sort((a, b) {
      final byLevel = b.y.compareTo(a.y);
      return byLevel != 0
          ? byLevel
          : (a.x - _center).abs().compareTo((b.x - _center).abs());
    });
    for (var index = 0; index < pieces.length; index++) {
      pieces[index].delay = index / pieces.length;
    }
    return pieces;
  }

  static List<_Wedge> _buildVoussoirs() {
    final pieces = <_Wedge>[];
    const colors = <Color>[
      Color(0xffdd8457),
      Color(0xffbe603f),
      Color(0xffcb714b),
      Color(0xffa74632),
      Color(0xffe0915f),
      Color(0xffb9573c),
    ];
    for (final side in const [-1, 1]) {
      for (var index = 0; index < 19; index++) {
        final t0 = index / 19;
        final t1 = (index + 1) / 19;
        final points = <Offset>[
          _curve(side, 185, 174, t0),
          _curve(side, 185, 174, t1),
          _curve(side, 127, 252, t1),
          _curve(side, 127, 252, t0),
        ];
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        path.close();
        pieces.add(
          _Wedge(path, colors[(index + (side == 1 ? 3 : 0)) % colors.length]),
        );
      }
    }
    for (var index = 0; index < pieces.length; index++) {
      pieces[index].delay = index / pieces.length;
    }
    return pieces;
  }

  static List<_PalmBlock> _buildPalms() {
    final blocks = <_PalmBlock>[];
    void addPalm(double baseX, double lean, double offset, double scale) {
      const height = 365.0;
      const levels = 27;
      double center(double t) => lean * (.08 * t + .92 * t * t);
      for (var level = 0; level < levels; level++) {
        final t = (level + .5) / levels;
        final width = 44 - 13 * t;
        final blockWidth = (width - 2.4) / 3;
        final dx =
            center(math.min(1.0, t + .004)) - center(math.max(0.0, t - .004));
        final angle = math.atan2(-height * .008, dx) - math.pi / 2;
        for (var column = 0; column < 3; column++) {
          final localX =
              center(t) +
              (column - 1.5) * blockWidth +
              (level.isOdd ? -blockWidth * .12 : 0);
          blocks.add(
            _PalmBlock(
              Offset(baseX + localX * scale, 617 - height * t * scale),
              (blockWidth - .7) * scale,
              (height / levels - 1.4) * scale,
              angle,
              offset + t * .52 + column * .001,
              const Color(0xff8f4b38),
              const Color(0xffd59b73),
            ),
          );
        }
      }
      final crown = Offset(baseX + center(1) * scale, 617 - height * scale);
      void leaf(
        double x,
        double y,
        double angle,
        double at,
        double width,
        double leafHeight,
      ) {
        blocks.add(
          _PalmBlock(
            crown + Offset(x * scale, y * scale),
            width * scale,
            leafHeight * scale,
            angle,
            at,
            const Color(0xff3a9361),
            const Color(0xffb4df90),
          ),
        );
      }

      for (var index = 0; index < 8; index++) {
        final angle = index * math.pi * 2 / 8;
        leaf(
          math.cos(angle) * 15,
          math.sin(angle) * 6,
          angle,
          offset + .55,
          14,
          11,
        );
      }
      for (var frond = 0; frond < 8; frond++) {
        final theta = -math.pi + .12 + frond * (math.pi + 1.25) / 7;
        final direction = math.cos(theta);
        final up = -.95 - math.sin(theta) * .34;
        final maxLength = frond == 0 || frond == 7
            ? 175.0
            : 148 + 20 * direction.abs();
        for (var segment = 0; segment < 13; segment++) {
          final q = (segment + .5) / 13;
          final distance = q * maxLength;
          final x = direction * distance;
          final y = up * distance + 88 * q * q;
          final dY = up + 176 * q / maxLength;
          final rotation = math.atan2(dY, direction);
          final at = offset + .60 + q * .30 + frond * .002;
          leaf(x, y, rotation, at, 15 + (1 - q) * 7, 8 + (1 - q) * 3);
          if (segment > 2 && segment < 12) {
            final length = math.sqrt(dY * dY + direction * direction);
            for (final sign in const [-1.0, 1.0]) {
              final side = 10 + 18 * (1 - q) * .15;
              leaf(
                x + (-dY / length) * sign * side,
                y + (direction / length) * sign * side,
                rotation + sign * math.pi * 29 / 180,
                offset + .64 + q * .28 + frond * .002,
                13,
                6,
              );
            }
          }
        }
      }
    }

    // The distant pair is painted first. The inner pair is therefore in front.
    addPalm(-88, -56, 0, .66);
    addPalm(1088, 56, .025, .66);
    addPalm(112, -56, .055, .62);
    addPalm(888, 56, .075, .62);
    return blocks;
  }

  static List<_LetterBrick> _buildLettering() {
    const glyphs = <String, List<String>>{
      'W': ['10001', '10001', '10001', '10101', '10101', '11011', '10001'],
      'E': ['11111', '10000', '10000', '11110', '10000', '10000', '11111'],
      'L': ['10000', '10000', '10000', '10000', '10000', '10000', '11111'],
      'C': ['01111', '10000', '10000', '10000', '10000', '10000', '01111'],
      'O': ['01110', '10001', '10001', '10001', '10001', '10001', '01110'],
      'M': ['10001', '11011', '10101', '10101', '10001', '10001', '10001'],
      '!': ['00100', '00100', '00100', '00100', '00100', '00000', '00100'],
    };
    final result = <_LetterBrick>[];
    const characters = 'WELCOME!';
    for (var index = 0; index < characters.length; index++) {
      final rows = glyphs[characters[index]]!;
      for (var row = 0; row < 7; row++) {
        for (var column = 0; column < 5; column++) {
          if (rows[row][column] != '1') continue;
          result.add(
            _LetterBrick(
              299 + index * 51 + column * 8,
              24 + row * 8,
              _palette[(index + row + column) % _palette.length],
              row,
              index,
              column,
            ),
          );
        }
      }
    }
    result.sort((a, b) {
      final byRow = b.row.compareTo(a.row);
      final byLetter = a.index.compareTo(b.index);
      return byRow != 0
          ? byRow
          : (byLetter != 0 ? byLetter : a.column.compareTo(b.column));
    });
    for (var index = 0; index < result.length; index++) {
      result[index].delay = index / result.length;
    }
    return result;
  }

  @override
  bool shouldRepaint(_IutGatewayPainter oldDelegate) => false;
}

class _Brick {
  _Brick(this.path, this.color, this.y, this.x);
  final Path path;
  final Color color;
  final double y;
  final double x;
  double delay = 0;
}

class _Wedge {
  _Wedge(this.path, this.color);
  final Path path;
  final Color color;
  double delay = 0;
}

class _PalmBlock {
  const _PalmBlock(
    this.center,
    this.width,
    this.height,
    this.rotation,
    this.delay,
    this.color,
    this.highlight,
  );
  final Offset center;
  final double width;
  final double height;
  final double rotation;
  final double delay;
  final Color color;
  final Color highlight;
}

class _LetterBrick {
  _LetterBrick(this.x, this.y, this.color, this.row, this.index, this.column);
  final double x;
  final double y;
  final Color color;
  final int row;
  final int index;
  final int column;
  double delay = 0;
  double get xShift => index.isOdd ? 10 : -10;
}
