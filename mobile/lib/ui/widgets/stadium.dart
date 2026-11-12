import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// [2026-11-06] The game's picture, drawn rather than shipped (no image weight): a stadium at night — a deep sky, two
/// floodlight towers throwing their light down, the stands as rows of tiny lit seats, and the pitch with its mowing
/// stripes and centre circle in perspective. Behind the home header, the sign-in and the next match.
class StadiumBackdrop extends StatelessWidget {
  const StadiumBackdrop({super.key, this.child, this.tint, this.pitch = true});

  final Widget? child;

  /// A club's colour mixed into the sky (the next match, a club's page).
  final Color? tint;
  final bool pitch;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _Stadium(
        sky: Color.lerp(p.bgDeep, tint ?? p.brandDark, tint == null ? .25 : .35)!,
        deep: p.bgDeep,
        grass: p.pitch,
        grassDark: p.pitchDark,
        light: p.goldLight,
        pitch: pitch,
      ),
      child: child,
    );
  }
}

class _Stadium extends CustomPainter {
  _Stadium({required this.sky, required this.deep, required this.grass, required this.grassDark, required this.light, required this.pitch});

  final Color sky, deep, grass, grassDark, light;
  final bool pitch;

  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.clipRect(r);
    canvas.drawRect(
      r,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [deep, sky, deep]).createShader(r),
    );

    final horizon = s.height * (pitch ? .58 : .8);
    // The stands: three tiers of seats, lit here and there.
    final rnd = math.Random(7);
    for (var tier = 0; tier < 3; tier++) {
      final y0 = horizon - (tier + 1) * s.height * .09;
      final band = Rect.fromLTWH(0, y0, s.width, s.height * .09);
      canvas.drawRect(band, Paint()..color = Color.lerp(deep, Colors.black, .25 + tier * .08)!);
      final dots = Paint();
      for (var x = 4.0; x < s.width; x += 7) {
        for (var y = y0 + 4; y < y0 + s.height * .09 - 2; y += 6) {
          final v = rnd.nextDouble();
          if (v > .55) {
            dots.color = Colors.white.withValues(alpha: .05 + v * .10);
            canvas.drawCircle(Offset(x + rnd.nextDouble() * 3, y), 1.1, dots);
          }
        }
      }
    }
    // The floodlights: towers at both ends, their beams falling on the pitch.
    for (final fx in [s.width * .03, s.width * .97]) {
      final top = Offset(fx, s.height * .03);
      canvas.drawRect(
        Rect.fromCenter(center: top.translate(0, s.height * .2), width: 3, height: s.height * .4),
        Paint()..color = Colors.black.withValues(alpha: .5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: top, width: 14, height: 5), const Radius.circular(2)),
        Paint()..color = light.withValues(alpha: .8),
      );
      canvas.drawCircle(
        top,
        s.width * .28,
        Paint()
          ..shader = RadialGradient(colors: [light.withValues(alpha: .22), light.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: top, radius: s.width * .28)),
      );
      final beam = Path()
        ..moveTo(top.dx - 10, top.dy)
        ..lineTo(top.dx + 10, top.dy)
        ..lineTo(s.width / 2 + (fx < s.width / 2 ? s.width * .1 : -s.width * .1), horizon + s.height * .3)
        ..lineTo(s.width / 2 - (fx < s.width / 2 ? -s.width * .25 : s.width * .25), horizon + s.height * .3)
        ..close();
      canvas.drawPath(beam, Paint()..color = light.withValues(alpha: .05));
    }
    if (!pitch) return;
    // The pitch in perspective: a trapezoid, its stripes, its halfway line and centre circle.
    final grassPath = Path()
      ..moveTo(s.width * .12, horizon)
      ..lineTo(s.width * .88, horizon)
      ..lineTo(s.width * 1.15, s.height)
      ..lineTo(-s.width * .15, s.height)
      ..close();
    canvas.save();
    canvas.clipPath(grassPath);
    canvas.drawRect(
      r,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [grassDark, grass]).createShader(r),
    );
    final stripe = Paint()..color = Colors.black.withValues(alpha: .10);
    for (var i = -6; i < 8; i += 2) {
      final x0 = s.width / 2 + i * s.width * .07, x1 = s.width / 2 + (i + 1) * s.width * .07;
      final path = Path()
        ..moveTo(x0, horizon)
        ..lineTo(x1, horizon)
        ..lineTo(s.width / 2 + (x1 - s.width / 2) * 2.2, s.height)
        ..lineTo(s.width / 2 + (x0 - s.width / 2) * 2.2, s.height)
        ..close();
      canvas.drawPath(path, stripe);
    }
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(grassPath, line);
    final mid = horizon + (s.height - horizon) * .55;
    canvas.drawLine(Offset(-s.width, mid), Offset(s.width * 2, mid), line);
    canvas.drawOval(Rect.fromCenter(center: Offset(s.width / 2, mid), width: s.width * .26, height: (s.height - horizon) * .38), line);
    canvas.restore();
    // A fade into the page below, so content sits on it cleanly.
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, deep.withValues(alpha: .65)],
          stops: const [.55, 1],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_Stadium old) => old.sky != sky || old.pitch != pitch;
}
