part of 'art.dart';

void _star(Canvas c, Offset at, double r, Color color) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5, rr = i.isEven ? r : r * .45;
    final pt = at + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  c.drawPath(p..close(), Paint()..color = color);
}

/// A comic burst with a word in it (BOING!, a whistle's PEEP), for the moment that deserves it.
void drawBurst(Canvas c, Offset at, String word, double t, {Color color = GlmBroadcast.goldLight, double size = 40}) {
  if (t <= 0 || t >= 1) return;
  final k = Curves.elasticOut.transform(t.clamp(0, 1)) * (1 - math.max(0, t - .75) * 4);
  final p = Path();
  for (var i = 0; i < 24; i++) {
    final a = i * math.pi / 12, rr = (i.isEven ? size : size * .62) * k;
    final pt = at + Offset(math.cos(a) * rr * 1.3, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  c.drawPath(p..close(), Paint()..color = color);
  c.drawPath(
    p,
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );
  text(c, word, at, size: size * .42 * k, color: GlmArt.ink, family: 'BarlowCondensed');
}

/// The rain: streaks across the frame and splashes on the grass (a rainy match, MomentClock::rainy).
void drawRain(Canvas c, double u, {double heavy = 1}) {
  final rnd = math.Random(5);
  final streak = Paint()
    ..color = Colors.white.withValues(alpha: .28 * heavy)
    ..strokeWidth = 1.4;
  for (var i = 0; i < 140 * heavy; i++) {
    final x0 = rnd.nextDouble() * (frameW + 200), speed = 500 + rnd.nextDouble() * 300;
    final y = (rnd.nextDouble() * frameH + u * speed) % (frameH + 40) - 20;
    final x = (x0 - y * .25) % (frameW + 100) - 50;
    c.drawLine(Offset(x, y), Offset(x - 6, y + 18), streak);
  }
  c.drawRect(const Rect.fromLTWH(0, 0, frameW, frameH), Paint()..color = GlmArt.rain.withValues(alpha: .18 * heavy));
}

/// A splash of water drops (a slide on a wet pitch).
void drawSplash(Canvas c, Offset at, double t) {
  if (t <= 0 || t >= 1) return;
  final rnd = math.Random(9);
  for (var i = 0; i < 14; i++) {
    final a = -math.pi + rnd.nextDouble() * math.pi, v = 30 + rnd.nextDouble() * 50;
    final p = at + Offset(math.cos(a) * v * t, math.sin(a) * v * t + 60 * t * t);
    c.drawCircle(p, 2.5 * (1 - t) + 1, Paint()..color = GlmArt.splash.withValues(alpha: 1 - t));
  }
}

/// A cloud of dust with flying limbs (a scuffle, a brawl).
void drawDust(Canvas c, Offset at, double u, {double size = 70}) {
  final rnd = math.Random(4);
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6 + u * 2, r = size * (.55 + .25 * math.sin(u * 6 + i));
    c.drawCircle(
      at + Offset(math.cos(a) * r * .9, math.sin(a) * r * .5),
      size * (.32 + rnd.nextDouble() * .12),
      Paint()..color = GlmArt.dust.withValues(alpha: .92),
    );
  }
  c.drawCircle(at, size * .6, Paint()..color = GlmArt.dustCore);
  for (var i = 0; i < 4; i++) {
    final a = u * 7 + i * 1.6;
    final from = at + Offset(math.cos(a) * size * .4, math.sin(a) * size * .25);
    c.drawLine(
      from,
      from + Offset(math.cos(a) * 26, math.sin(a) * 16),
      Paint()
        ..color = GlmArt.skin
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }
  drawStars(c, at + Offset(0, -size * .6), u, r: size * .5);
}
