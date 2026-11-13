import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/tokens.g.dart';

/// The ground split on a gold diagonal, each half in its side's colour, speed lines running across.
class SimSplit extends CustomPainter {
  SimSplit({required this.home, required this.away, required this.gold, required this.run, this.wide = false});

  final Color home, away, gold;
  final double run;

  /// Landscape: the diagonal runs from the top to the bottom, the home side at the reading start.
  final bool wide;

  @override
  void paint(Canvas canvas, Size s) {
    final ink = glmNight.bgDeep;
    if (wide) {
      // Home on the right (Arabic reads from it), away on the left: the gold line from the top at 58% to the foot at 42%.
      final x1 = s.width * .58, x2 = s.width * .42;
      final right = Path()..addPolygon([Offset(x1, 0), Offset(s.width, 0), Offset(s.width, s.height), Offset(x2, s.height)], true);
      final left = Path()..addPolygon([Offset.zero, Offset(x1, 0), Offset(x2, s.height), Offset(0, s.height)], true);
      canvas.drawPath(right, Paint()..color = Color.lerp(ink, home, .32)!);
      canvas.drawPath(left, Paint()..color = Color.lerp(ink, away, .32)!);
      for (final (c, at) in [(home, Offset(s.width * .82, s.height * .3)), (away, Offset(s.width * .18, s.height * .7))]) {
        canvas.drawCircle(
          at,
          s.height * 1.1,
          Paint()
            ..shader = RadialGradient(colors: [c.withValues(alpha: .42), c.withValues(alpha: 0)])
                .createShader(Rect.fromCircle(center: at, radius: s.height * 1.1)),
        );
      }
      final lines = Paint()
        ..color = Colors.white.withValues(alpha: .06)
        ..strokeWidth = 10;
      final dy = run * 90;
      for (final x in [.12, .26, .74, .88]) {
        canvas.drawLine(Offset(s.width * x + 40, -90 + dy), Offset(s.width * x - 40, s.height + dy), lines);
      }
      canvas.drawLine(
        Offset(x1, 0),
        Offset(x2, s.height),
        Paint()
          ..color = gold
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6),
      );
      return;
    }
    final a = s.height * .30, b = s.height * .56;
    final top = Path()..addPolygon([Offset.zero, Offset(s.width, 0), Offset(s.width, b), Offset(0, a)], true);
    final bottom = Path()..addPolygon([Offset(0, a), Offset(s.width, b), Offset(s.width, s.height), Offset(0, s.height)], true);
    canvas.drawPath(top, Paint()..color = Color.lerp(ink, home, .32)!);
    canvas.drawPath(bottom, Paint()..color = Color.lerp(ink, away, .32)!);
    canvas.drawCircle(
      Offset(s.width * .8, s.height * .18),
      s.width * .7,
      Paint()
        ..shader = RadialGradient(colors: [home.withValues(alpha: .4), home.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: Offset(s.width * .8, s.height * .18), radius: s.width * .7)),
    );
    canvas.drawCircle(
      Offset(s.width * .2, s.height * .7),
      s.width * .7,
      Paint()
        ..shader = RadialGradient(colors: [away.withValues(alpha: .45), away.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: Offset(s.width * .2, s.height * .7), radius: s.width * .7)),
    );
    final lines = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 10;
    final dx = -run * 120;
    for (final y in [.14, .24, .66, .76]) {
      canvas.drawLine(Offset(dx - 120, s.height * y), Offset(s.width + 120 + dx, s.height * y + (b - a)), lines);
    }
    canvas.drawLine(
      Offset(0, a),
      Offset(s.width, b),
      Paint()
        ..color = gold
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6),
    );
  }

  @override
  bool shouldRepaint(SimSplit old) => old.run != run || old.home != home || old.away != away || old.wide != wide;
}

/// Sparks rising, each on its own path.
class SimSparks extends CustomPainter {
  SimSparks({required this.t, required this.colors});

  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * s.width, y0 = s.height * (.35 + rnd.nextDouble() * .5), off = rnd.nextDouble();
      final k = (t + off) % 1;
      canvas.drawCircle(
        Offset(x + math.sin(k * 6 + i) * 8, y0 - k * 240),
        3 * (1 - k * .7),
        Paint()..color = colors[i % colors.length].withValues(alpha: (1 - k) * (k < .15 ? k / .15 : 1)),
      );
    }
  }

  @override
  bool shouldRepaint(SimSparks old) => old.t != t;
}
