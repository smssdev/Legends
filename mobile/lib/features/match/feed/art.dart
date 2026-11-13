import '../../../ui/tokens.g.dart';
import '../../../ui/art_palette.dart';
import '../../../ui/theme.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'art_star.dart';

/// [Sprint 44 B1] The cartoon's drawing kit for the app's clips, drawn in code (no images): the broadcast camera behind
/// the striker looking at the goal, its perspective, the stands and the LEGENDS boards, a cartoon footballer (his number
/// on his back, or his face when he turns), the keeper, the referee, the ball and its shadow. The scenes (clips.dart)
/// only say who is where at each instant; positions are logical (a 1000 × 562 frame), the ground's y giving the depth.

const double frameW = 1000, frameH = 562;

/// The goal: its posts, bar and line on the far ground.
const double postL = 405, postR = 595, goalLine = 292, barY = 205;

/// How big a thing standing at [y] looks (far small, near big).
double depth(double y) => (0.5 + (y - goalLine) / (frameH - goalLine) * 0.72).clamp(0.42, 1.3);

double lerp(double a, double b, double t) => a + (b - a) * t;

/// 0..1 over [a, b] seconds, eased or not.
double seg(double u, double a, double b, [Curve curve = Curves.linear]) => curve.transform(((u - a) / (b - a)).clamp(0.0, 1.0));

Offset lerpO(Offset a, Offset b, double t) => Offset(lerp(a.dx, b.dx, t), lerp(a.dy, b.dy, t));

/// A point along a quadratic curve (a curled free kick, a cross).
Offset bezier(Offset a, Offset c, Offset b, double t) => Offset(
  (1 - t) * (1 - t) * a.dx + 2 * (1 - t) * t * c.dx + t * t * b.dx,
  (1 - t) * (1 - t) * a.dy + 2 * (1 - t) * t * c.dy + t * t * b.dy,
);

/// The colours of one clip: both kits, the keepers', the referee's, the grass, the night.
class ClipLook {
  const ClipLook({
    required this.kits,
    required this.keeper,
    required this.referee,
    required this.grass,
    required this.grassDark,
    required this.gold,
    required this.night,
    this.rain = false,
  });

  /// Each side's shirt and its ink (the number).
  final Map<String, (Color, Color)> kits;
  final Color keeper, referee, grass, grassDark, gold, night;
  final bool rain;

  Color shirt(String side) => kits[side]!.$1;
  Color ink(String side) => kits[side]!.$2;
}

/// A colour far from both kits for the keepers (and one for the referee), as the web picks them (art.ts).
Color farFrom(List<Color> taken, List<Color> options) {
  double d(Color a, Color b) => (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();
  return options.reduce((best, c) => taken.map((t) => d(c, t)).reduce(math.min) > taken.map((t) => d(best, t)).reduce(math.min) ? c : best);
}

/// The canvas in the clip's logical frame: covering the widget, centred.
void fitFrame(Canvas c, Size s) {
  final k = math.max(s.width / frameW, s.height / frameH);
  c.translate((s.width - frameW * k) / 2, (s.height - frameH * k) / 2);
  c.scale(k);
}

void text(
  Canvas c,
  String t,
  Offset at, {
  double size = 16,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w800,
  String? family,
  TextAlign align = TextAlign.center,
  double letter = 0,
  List<Shadow>? shadows,
}) {
  final p = TextPainter(
    text: TextSpan(
      text: t,
      style: glmDrawnText(
        size,
        color: color,
        fontWeight: weight,
        fontFamily: family ?? 'Tajawal',
        letterSpacing: letter,
        height: 1,
        shadows: shadows,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
  )..layout();
  final dx = align == TextAlign.center
      ? p.width / 2
      : align == TextAlign.right
      ? p.width
      : 0.0;
  p.paint(c, at - Offset(dx, p.height / 2));
}

/// The stadium behind the goal: the night sky, the stands full of fans (bouncing by [roar]), the LEGENDS boards, and the
/// pitch with its mowing stripes, its box and its goal.
void drawGround(Canvas c, ClipLook l, double u, {double roar = 0, bool goal = true, Map<String, (Color, Color)>? fans}) {
  final sky = const Rect.fromLTWH(0, 0, frameW, 150);
  c.drawRect(
    sky,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [l.night, Color.lerp(l.night, Colors.black, .4)!],
      ).createShader(sky),
  );
  // The fans: rows of heads and shoulders in both clubs' colours, more of the home side's.
  final rnd = math.Random(3);
  final colours = [l.shirt('home'), l.shirt('home'), l.shirt('home'), l.shirt('away'), Colors.white70];
  for (var row = 0; row < 5; row++) {
    final y = 30.0 + row * 24;
    for (var x = -6.0 + (row.isOdd ? 9 : 0); x < frameW + 10; x += 18) {
      final bounce = roar > 0 ? math.sin(u * 14 + x * .07 + row) * 4 * roar - 2 * roar : math.sin(u * 2 + x) * .6;
      final col = colours[rnd.nextInt(colours.length)];
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y + 12 + bounce), width: 14, height: 14), const Radius.circular(5)),
        Paint()..color = Color.lerp(col, Colors.black, .35)!,
      );
      c.drawCircle(Offset(x, y + bounce), 5, Paint()..color = GlmArt.skin.withValues(alpha: .85));
      if (roar > .4 && rnd.nextDouble() > .6) {
        c.drawLine(
          Offset(x - 4, y + 4 + bounce),
          Offset(x - 8, y - 8 + bounce - roar * 4),
          Paint()
            ..color = Color.lerp(col, Colors.black, .2)!
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }
  // The floodlights' glow over the stands.
  for (final fx in [120.0, 880.0]) {
    c.drawCircle(
      Offset(fx, 0),
      260,
      Paint()
        ..shader = RadialGradient(colors: [l.gold.withValues(alpha: .18), l.gold.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: Offset(fx, 0), radius: 260)),
    );
  }
  // The boards.
  final boards = const Rect.fromLTWH(0, 150, frameW, 26);
  c.drawRect(boards, Paint()..shader = const LinearGradient(colors: GlmArt.boards).createShader(boards));
  for (var x = 60.0; x < frameW; x += 220) {
    text(c, 'LEGENDS', Offset(x + (u * 18) % 220 - 60, 163), size: 15, color: l.gold, letter: 4);
  }
  // The grass: stripes fanning out toward the camera.
  final grass = const Rect.fromLTWH(0, 176, frameW, frameH - 176);
  c.drawRect(
    grass,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [l.grassDark, l.grass],
      ).createShader(grass),
  );
  final stripe = Paint()..color = Colors.black.withValues(alpha: .08);
  for (var i = -8; i <= 8; i += 2) {
    final x0 = 500 + i * 60.0, x1 = 500 + (i + 1) * 60.0;
    c.drawPath(
      Path()
        ..moveTo(x0, 176)
        ..lineTo(x1, 176)
        ..lineTo(500 + (x1 - 500) * 3.2, frameH)
        ..lineTo(500 + (x0 - 500) * 3.2, frameH)
        ..close(),
      stripe,
    );
  }
  final line = Paint()
    ..color = Colors.white.withValues(alpha: .7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  // The goal line, the six-yard box, the box, the spot and the arc.
  c.drawLine(const Offset(0, goalLine), const Offset(frameW, goalLine), line);
  c.drawPath(
    Path()
      ..moveTo(355, goalLine)
      ..lineTo(330, 322)
      ..lineTo(670, 322)
      ..lineTo(645, goalLine),
    line,
  );
  c.drawPath(
    Path()
      ..moveTo(250, goalLine)
      ..lineTo(170, 420)
      ..lineTo(830, 420)
      ..lineTo(750, goalLine),
    line,
  );
  c.drawOval(Rect.fromCenter(center: const Offset(500, 392), width: 7, height: 4), Paint()..color = Colors.white70);
  c.drawArc(Rect.fromCenter(center: const Offset(500, 420), width: 200, height: 60), 0, math.pi, false, line);
  if (goal) drawGoal(c, l);
}

/// The goal: its net (bulging at [bulge] where the ball hits), its posts and bar.
void drawGoal(Canvas c, ClipLook l, {Offset? bulge, double give = 0}) {
  final net = Paint()
    ..color = Colors.white.withValues(alpha: .35)
    ..strokeWidth = 1;
  Offset pull(Offset p) {
    if (bulge == null || give == 0) return p;
    final d = (p - bulge).distance;
    final k = math.max(0, 1 - d / 70) * give;
    return p + Offset(0, -10 * k) + (p - bulge) * (-.15 * k);
  }

  // The net's back, a little higher and narrower than the frame.
  for (var x = postL; x <= postR; x += 12) {
    c.drawLine(pull(Offset(x, barY)), pull(Offset(x + (x - 500) * -.05, goalLine - 18)), net);
  }
  for (var y = barY; y <= goalLine - 18; y += 10) {
    final a = Offset(postL + (y - barY) * .15, y), b = Offset(postR - (y - barY) * .15, y);
    c.drawLine(pull(a), pull(b), net);
  }
  final post = Paint()
    ..color = Colors.white
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;
  c.drawLine(const Offset(postL, goalLine), const Offset(postL, barY), post);
  c.drawLine(const Offset(postR, goalLine), const Offset(postR, barY), post);
  c.drawLine(const Offset(postL, barY), const Offset(postR, barY), post);
}

/// A skin tone and a hair colour from the player's number, so a player looks the same each time.
(Color, Color) _skin(String no) {
  final h = no.codeUnits.fold(7, (a, b) => a * 31 + b);
  const skins = GlmArt.skins;
  const hairs = GlmArt.hairs;
  return (skins[h % skins.length], hairs[(h ~/ 4) % hairs.length]);
}

/// A cartoon footballer standing (or running) at ([x], [y]) on the ground.
/// [run]: the stride's phase (null: still). [kick]: the striking leg's swing, 0..1. [arms]: 0 down, 1 up in joy.
/// [tilt]: the body's lean or fall in radians (a dive, a tumble). [lift]: off the ground (a jump). [front]: facing
/// the camera (the face), otherwise his back (the number). [hold]: what his raised hand holds (a card's colour).
void drawPlayer(
  Canvas c,
  double x,
  double y, {
  required Color shirt,
  required Color ink,
  Color? shorts,
  String no = '',
  double? run,
  double kick = 0,
  double arms = 0,
  double tilt = 0,
  double lift = 0,
  bool front = false,
  Color? hold,
  bool gloves = false,
  double scale = 1,
  bool shadow = true,
  String face = 'idle',
  double armOut = 0,
}) {
  final s = depth(y) * scale;
  final (skin, hair) = _skin(no.isEmpty ? '$x' : no);
  if (shadow) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 44 * s * (1 - lift / 200).clamp(.4, 1), height: 10 * s),
      Paint()..color = Colors.black.withValues(alpha: .28),
    );
  }
  c.save();
  c.translate(x, y - lift * s);
  c.rotate(tilt);
  final leg = Paint()
    ..color = skin
    ..strokeWidth = 7 * s
    ..strokeCap = StrokeCap.round;
  final sock = Paint()
    ..color = shorts ?? Color.lerp(shirt, Colors.black, .2)!
    ..strokeWidth = 8 * s
    ..strokeCap = StrokeCap.round;
  final swing = run == null ? 0.0 : math.sin(run) * .55;
  final hip = Offset(0, -42 * s);
  Offset foot(double a) => hip + Offset(math.sin(a) * 40 * s, math.cos(a) * 40 * s);
  final fl = foot(swing + .08), fr = foot(-swing - .08 - kick * 1.4);
  for (final f in [fl, fr]) {
    c.drawLine(hip, f, leg);
    c.drawLine(lerpO(hip, f, .55), f, sock);
    c.drawCircle(f, 4.5 * s, Paint()..color = GlmArt.boot);
  }
  // The shorts and the shirt.
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: hip + Offset(0, -2 * s), width: 30 * s, height: 14 * s), Radius.circular(4 * s)),
    Paint()..color = shorts ?? Colors.white,
  );
  final torso = RRect.fromRectAndRadius(Rect.fromLTRB(-17 * s, -88 * s, 17 * s, -44 * s), Radius.circular(9 * s));
  c.drawRRect(
    torso,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(shirt, Colors.white, .18)!, shirt],
      ).createShader(torso.outerRect),
  );
  // The arms: down and swinging, raised, or out wide (a protest, an appeal).
  final arm = Paint()
    ..color = skin
    ..strokeWidth = 6 * s
    ..strokeCap = StrokeCap.round;
  final sleeve = Paint()
    ..color = shirt
    ..strokeWidth = 8 * s
    ..strokeCap = StrokeCap.round;
  for (final side in [-1.0, 1.0]) {
    final sh = Offset(side * 15 * s, -82 * s);
    final down = Offset(side * 22 * s, -50 * s + (run == null ? 0 : math.sin(run + (side > 0 ? 0 : math.pi)) * 6 * s));
    final up = Offset(side * 26 * s, -122 * s);
    final out = Offset(side * 42 * s, -84 * s);
    var hand = lerpO(lerpO(down, out, armOut), up, arms);
    if (hold != null && side > 0) hand = Offset(14 * s, -128 * s);
    c.drawLine(sh, lerpO(sh, hand, .45), sleeve);
    c.drawLine(lerpO(sh, hand, .4), hand, arm);
    if (gloves) c.drawCircle(hand, 6 * s, Paint()..color = GlmArt.gloves);
    if (hold != null && side > 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: hand + Offset(4 * s, -12 * s), width: 16 * s, height: 22 * s),
          Radius.circular(2 * s),
        ),
        Paint()..color = hold,
      );
      c.drawCircle(
        hand + Offset(4 * s, -12 * s),
        22 * s,
        Paint()
          ..shader = RadialGradient(colors: [hold.withValues(alpha: .45), hold.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: hand + Offset(4 * s, -12 * s), radius: 22 * s)),
      );
    }
  }
  // The number on his back, or his face.
  if (!front && no.isNotEmpty) text(c, no, Offset(0, -66 * s), size: 19 * s, color: ink, family: 'BarlowCondensed');
  final head = Offset(0, -101 * s);
  c.drawRect(Rect.fromCenter(center: Offset(0, -90 * s), width: 8 * s, height: 6 * s), Paint()..color = skin);
  c.drawCircle(head, 13 * s, Paint()..color = skin);
  if (front) {
    c.drawArc(Rect.fromCircle(center: head, radius: 13.5 * s), math.pi, math.pi, true, Paint()..color = hair);
    _face(c, head, s, face);
  } else {
    c.drawCircle(head + Offset(0, -2 * s), 12.5 * s, Paint()..color = hair);
  }
  c.restore();
}

void _face(Canvas c, Offset h, double s, String mood) {
  final ink = Paint()
    ..color = GlmArt.ink
    ..strokeWidth = 1.6 * s
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final dot = Paint()..color = GlmArt.ink;
  for (final e in [-4.5, 4.5]) {
    if (mood == 'joy' || mood == 'cheer') {
      c.drawArc(Rect.fromCenter(center: h + Offset(e * s, 1 * s), width: 5 * s, height: 4 * s), math.pi, math.pi, false, ink);
    } else {
      c.drawCircle(h + Offset(e * s, 1 * s), (mood == 'surprise' ? 2.2 : 1.6) * s, dot);
    }
    if (mood == 'angry') {
      c.drawLine(
        h + Offset((e - 2.5) * s, -3.5 * s + (e > 0 ? 1.5 : 0) * s),
        h + Offset((e + 2.5) * s, -3.5 * s + (e > 0 ? 0 : 1.5) * s),
        ink,
      );
    }
    if (mood == 'worried' || mood == 'sad') {
      c.drawLine(h + Offset((e - 2.5) * s, -3 * s + (e > 0 ? 0 : 1.2) * s), h + Offset((e + 2.5) * s, -3 * s + (e > 0 ? 1.2 : 0) * s), ink);
    }
  }
  final m = h + Offset(0, 6 * s);
  switch (mood) {
    case 'joy' || 'cheer':
      c.drawArc(Rect.fromCenter(center: m, width: 10 * s, height: 7 * s), 0, math.pi, true, Paint()..color = GlmArt.mouth);
    case 'angry':
      c.drawRect(Rect.fromCenter(center: m, width: 9 * s, height: 3 * s), Paint()..color = GlmArt.mouth);
    case 'sad' || 'worried':
      c.drawArc(Rect.fromCenter(center: m + Offset(0, 2 * s), width: 9 * s, height: 6 * s), math.pi, math.pi, false, ink);
    case 'surprise':
      c.drawOval(Rect.fromCenter(center: m, width: 5 * s, height: 6 * s), Paint()..color = GlmArt.mouth);
    default:
      c.drawLine(m - Offset(3.5 * s, 0), m + Offset(3.5 * s, 0), ink);
  }
}

/// The ball at ([x], [y]) on the ground, [z] in the air, spinning by [spin]; its shadow on the grass.
void drawBall(Canvas c, double x, double y, {double z = 0, double spin = 0, double scale = 1}) {
  final s = depth(y) * scale;
  c.drawOval(
    Rect.fromCenter(center: Offset(x, y), width: 16 * s / (1 + z / 120), height: 5 * s / (1 + z / 120)),
    Paint()..color = Colors.black.withValues(alpha: .3),
  );
  final at = Offset(x, y - 7 * s - z * s);
  final r = 7.5 * s;
  c.drawCircle(
    at,
    r,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.4, -.4),
        colors: [Colors.white, GlmArt.ballShade],
      ).createShader(Rect.fromCircle(center: at, radius: r)),
  );
  final patch = Paint()..color = GlmArt.ballPatch;
  for (var i = 0; i < 3; i++) {
    final a = spin + i * 2.1;
    c.drawCircle(at + Offset(math.cos(a) * r * .5, math.sin(a) * r * .5), r * .26, patch);
  }
}

/// A speed trail behind a ball in flight.
void drawTrail(Canvas c, List<Offset> pts, Color color) {
  for (var i = 1; i < pts.length; i++) {
    c.drawLine(
      pts[i - 1],
      pts[i],
      Paint()
        ..color = color.withValues(alpha: .08 + .5 * i / pts.length)
        ..strokeWidth = 2 + 6 * i / pts.length
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Little stars circling a dazed head.
void drawStars(Canvas c, Offset head, double u, {double r = 22, Color color = GlmBroadcast.goldLight}) {
  for (var i = 0; i < 3; i++) {
    final a = u * 5 + i * 2.1;
    _star(c, head + Offset(math.cos(a) * r, math.sin(a) * r * .35), 6, color);
  }
}
