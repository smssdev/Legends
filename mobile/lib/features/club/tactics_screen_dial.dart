part of 'tactics_screen.dart';

/// A dial as the manager games show it: its title, its word, its number in a black box and the slider.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.title,
    required this.value,
    required this.word,
    required this.low,
    required this.high,
    required this.onChanged,
  });

  final String title, word, low, high;
  final num value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: ShapeDecoration(shape: GlmCut.shape(14), gradient: _cardFill),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Column(
      children: [
        Text(
          title,
          style: glmText(GlmType.bodyLg, color: _titleBlue, fontWeight: FontWeight.w700),
        ),
        Text(
          word,
          style: glmText(GlmType.headline, color: Colors.white, fontWeight: FontWeight.w800),
        ),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: GlmStage.pill,
                  inactiveTrackColor: Colors.black.withValues(alpha: .45),
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                ),
                child: Slider(value: value.toDouble(), min: 0, max: 100, divisions: 100, onChanged: (v) => onChanged(v.round())),
              ),
            ),
            const SizedBox(width: 12),
            // [Sprint 46, the polish] The number's box lit by where the dial stands: cool low, gold balanced, red high.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: value < 40
                        ? GlmStage.accent
                        : value > 60
                        ? GlmTacticsArt.press
                        : GlmTacticsArt.gold,
                    width: 4,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (value < 40
                                ? GlmStage.accent
                                : value > 60
                                ? GlmTacticsArt.press
                                : GlmTacticsArt.gold)
                            .withValues(alpha: .35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Text(
                '${value.round()}',
                style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(low, style: glmText(GlmType.caption, color: Colors.white54)),
            const Spacer(),
            Text(high, style: glmText(GlmType.caption, color: Colors.white54)),
            const SizedBox(width: 66),
          ],
        ),
      ],
    ),
  );
}

/// A little pitch in perspective, our own drawing, its two goals; the art's arrows go on top.
void _miniPitch(Canvas c, Size s, Rect f) {
  final grass = Path()
    ..moveTo(f.left + f.width * .08, f.top)
    ..lineTo(f.right - f.width * .08, f.top)
    ..lineTo(f.right, f.bottom)
    ..lineTo(f.left, f.bottom)
    ..close();
  c.drawPath(grass.shift(Offset(0, f.height * .1)), Paint()..color = GlmTacticsArt.earth);
  c.drawPath(
    grass,
    Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: GlmTacticsArt.grass).createShader(f),
  );
  final line = Paint()
    ..color = Colors.white.withValues(alpha: .7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  c.drawPath(grass, line);
  c.drawLine(Offset(f.center.dx, f.top), Offset(f.center.dx, f.bottom), line);
  c.drawOval(Rect.fromCenter(center: f.center, width: f.width * .14, height: f.height * .42), line);
  for (final left in [true, false]) {
    final x = left ? f.left + f.width * .06 : f.right - f.width * .06, d = left ? 1.0 : -1.0;
    c.drawRect(Rect.fromPoints(Offset(x, f.top + f.height * .25), Offset(x + d * f.width * .1, f.bottom - f.height * .25)), line);
  }
}

void _arrowLine(Canvas c, List<Offset> pts, Color color, {double width = 4, double t = 1}) {
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  if (pts.length == 3) {
    path.quadraticBezierTo(pts[1].dx, pts[1].dy, pts[2].dx, pts[2].dy);
  } else {
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
  }
  // Drawn as far as [t] along its length: the arrow traces itself in, its head arriving last.
  final drawn = Path();
  for (final m in path.computeMetrics()) {
    drawn.addPath(m.extractPath(0, m.length * t.clamp(0, 1)), Offset.zero);
  }
  c.drawPath(
    drawn,
    Paint()
      ..color = color.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 2.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  c.drawPath(
    drawn,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  if (t < .98) return;
  final end = pts.last, before = pts.length == 3 ? pts[1] : pts[pts.length - 2];
  final a = math.atan2(end.dy - before.dy, end.dx - before.dx);
  c.drawPath(
    Path()
      ..moveTo(end.dx + math.cos(a) * width * 2, end.dy + math.sin(a) * width * 2)
      ..lineTo(end.dx + math.cos(a + 2.4) * width * 2.4, end.dy + math.sin(a + 2.4) * width * 2.4)
      ..lineTo(end.dx + math.cos(a - 2.4) * width * 2.4, end.dy + math.sin(a - 2.4) * width * 2.4)
      ..close(),
    Paint()..color = color,
  );
}

/// The plan drawn on its pitch (attacking toward the reading start): short passes weaving, a counter's long ball after
/// the short ones, the long ball's arc, both wings, shots from distance.
class _PlanArt extends CustomPainter {
  _PlanArt(this.plan, [this.t = 1]);

  final String plan;
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final f = Rect.fromLTWH(s.width * .04, s.height * .22, s.width * .92, s.height * .62);
    _miniPitch(c, s, f);
    const red = GlmTacticsArt.theirs, blue = GlmTacticsArt.mine;
    Offset at(double u, double v) => Offset(f.left + f.width * u, f.top + f.height * v);
    switch (plan) {
      case 'passing':
        _arrowLine(
          c,
          [at(.85, .5), at(.75, .5), at(.68, .3), at(.6, .65), at(.52, .35), at(.44, .7), at(.36, .45), at(.18, .5)],
          red,
          width: 3,
          t: t,
        );
      case 'counter':
        _arrowLine(c, [at(.82, .7), at(.62, .75)], blue, width: 3, t: t);
        _arrowLine(c, [at(.6, .72), at(.4, .68)], blue, width: 3, t: t);
        _arrowLine(c, [at(.78, .4), at(.5, -.3), at(.22, .4)], red, t: t);
      case 'long':
        _arrowLine(c, [at(.8, .55), at(.5, -.5), at(.2, .55)], red, width: 5, t: t);
      case 'wings':
        _arrowLine(c, [at(.72, .12), at(.25, .12)], red, t: t);
        _arrowLine(c, [at(.72, .88), at(.25, .88)], red, t: t);
      default:
        for (final (u, v) in [(.42, .3), (.44, .5), (.42, .72)]) {
          _arrowLine(c, [at(u, v), at(u - .18, v + .02)], red, width: 3, t: t);
          c.drawCircle(at(u + .03, v), 5, Paint()..color = Colors.white);
        }
    }
  }

  @override
  bool shouldRepaint(_PlanArt old) => old.plan != plan || old.t != t;
}

/// How hard they tackle: a boot meeting the ball, the cards it may bring (none, a yellow, a yellow and a red).
class _TackleArt extends CustomPainter {
  _TackleArt(this.level);

  final int level;

  @override
  void paint(Canvas c, Size s) {
    final mid = Offset(s.width / 2, s.height * .55);
    // The boot's studs and sole, sliding in harder with each level.
    final boot = Path()
      ..moveTo(mid.dx - 60, mid.dy - 6)
      ..quadraticBezierTo(mid.dx - 20, mid.dy - 30, mid.dx + 14, mid.dy - 14)
      ..lineTo(mid.dx + 24, mid.dy + 4)
      ..lineTo(mid.dx - 60, mid.dy + 10)
      ..close();
    c.save();
    c.translate(-level * 8.0, 0);
    c.rotate(-.06 * level);
    c.drawPath(boot, Paint()..color = GlmTacticsArt.boot);
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(mid.dx - 52 + i * 18.0, mid.dy + 10, 6, 6), Paint()..color = GlmTacticsArt.studs);
    }
    c.restore();
    c.drawCircle(Offset(mid.dx + 44, mid.dy - 2), 14, Paint()..color = Colors.white);
    c.drawCircle(Offset(mid.dx + 44, mid.dy - 2), 5, Paint()..color = GlmTacticsArt.ball);
    // Speed lines for the keener levels.
    for (var i = 0; i < level; i++) {
      c.drawLine(
        Offset(mid.dx - 96 - i * 6.0, mid.dy - 14 + i * 9.0),
        Offset(mid.dx - 72, mid.dy - 14 + i * 9.0),
        Paint()
          ..color = Colors.white38
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    final cards = [if (level >= 2) GlmArt.yellowCard, if (level >= 3) GlmTacticsArt.theirs];
    for (final (i, col) in cards.indexed) {
      c.save();
      c.translate(s.width / 2 + 70 + i * 22.0, s.height * .22);
      c.rotate(.15 + i * .12);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -17, 24, 34), const Radius.circular(3)), Paint()..color = col);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_TackleArt old) => old.level != level;
}

/// The three lines on a tall pitch (attacking upward), each order an arrow: the forwards back, supporting or only up;
/// the midfield back, holding or pushing on; the defence holding, the full-backs going up, or stepping into midfield.
class _LinesArt extends CustomPainter {
  _LinesArt(this.att, this.mid, this.def);

  final String att, mid, def;

  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(12));
    c.drawRRect(r, Paint()..color = GlmTacticsArt.turf);
    c.save();
    c.clipRRect(r);
    for (var i = 0; i < 8; i += 2) {
      c.drawRect(Rect.fromLTWH(0, s.height * i / 8, s.width, s.height / 8), Paint()..color = Colors.white.withValues(alpha: .05));
    }
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), line);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.width * .14, line);
    for (final top in [true, false]) {
      final y = top ? 0.0 : s.height;
      final d = top ? 1.0 : -1.0;
      c.drawRect(Rect.fromPoints(Offset(s.width * .24, y), Offset(s.width * .76, y + d * s.height * .16)), line);
      c.drawRect(Rect.fromPoints(Offset(s.width * .38, y), Offset(s.width * .62, y + d * s.height * .06)), line);
    }
    c.restore();
    Offset at(double u, double v) => Offset(s.width * u, s.height * v);
    const blue = GlmTacticsArt.zone, orange = GlmTacticsArt.mid, red = GlmTacticsArt.press;
    void cross(Offset o, Color col) {
      for (final d in [const Offset(1, 0), const Offset(0, 1)]) {
        _arrowLine(c, [o, o + d * 26], col, width: 4);
        _arrowLine(c, [o, o - d * 26], col, width: 4);
      }
    }

    switch (att) {
      case 'only':
        _arrowLine(c, [at(.5, .3), at(.5, .14)], blue, width: 7);
      case 'support':
        _arrowLine(c, [at(.5, .14), at(.5, .3)], blue, width: 7);
      default:
        _arrowLine(c, [at(.5, .12), at(.5, .36)], blue, width: 7);
    }
    switch (mid) {
      case 'push':
        _arrowLine(c, [at(.46, .6), at(.36, .5), at(.38, .38)], orange, width: 7);
        _arrowLine(c, [at(.54, .6), at(.64, .5), at(.62, .38)], orange, width: 7);
      case 'def':
        _arrowLine(c, [at(.3, .48), at(.3, .62)], orange, width: 6);
        _arrowLine(c, [at(.7, .48), at(.7, .62)], orange, width: 6);
      default:
        cross(at(.24, .5), orange);
        cross(at(.76, .5), orange);
    }
    switch (def) {
      case 'fullbacks':
        _arrowLine(c, [at(.16, .9), at(.16, .66)], red, width: 7);
        _arrowLine(c, [at(.84, .9), at(.84, .66)], red, width: 7);
      case 'mid':
        _arrowLine(c, [at(.5, .88), at(.5, .66)], red, width: 7);
      default:
        cross(at(.5, .8), red);
    }
  }

  @override
  bool shouldRepaint(_LinesArt old) => old.att != att || old.mid != mid || old.def != def;
}

/// The marking: an area for each defender (zone), or a line from each to his man.
class _MarkArt extends CustomPainter {
  _MarkArt(this.mode);

  final String mode;

  @override
  void paint(Canvas c, Size s) {
    final f = Rect.fromLTWH(s.width * .1, s.height * .2, s.width * .8, s.height * .66);
    _miniPitch(c, s, f);
    Offset at(double u, double v) => Offset(f.left + f.width * u, f.top + f.height * v);
    for (var i = 0; i < 4; i++) {
      final d = at(.3, .14 + i * .24), a = at(.42, .2 + i * .22);
      if (mode == 'zone') {
        c.drawOval(
          Rect.fromCenter(center: d, width: f.width * .22, height: f.height * .22),
          Paint()..color = GlmTacticsArt.zone.withValues(alpha: .35),
        );
      } else {
        c.drawLine(
          d,
          a,
          Paint()
            ..color = GlmTacticsArt.gold
            ..strokeWidth = 2.5,
        );
      }
      c.drawCircle(d, 6, Paint()..color = GlmTacticsArt.mine);
      c.drawCircle(a, 6, Paint()..color = GlmTacticsArt.theirs);
    }
  }

  @override
  bool shouldRepaint(_MarkArt old) => old.mode != mode;
}

/// The offside trap: the back line stepping up together and the assistant's flag up (or the line holding).
class _TrapArt extends CustomPainter {
  _TrapArt(this.on);

  final bool on;

  @override
  void paint(Canvas c, Size s) {
    final f = Rect.fromLTWH(s.width * .1, s.height * .2, s.width * .8, s.height * .66);
    _miniPitch(c, s, f);
    Offset at(double u, double v) => Offset(f.left + f.width * u, f.top + f.height * v);
    final x = on ? .44 : .3;
    if (on) {
      c.drawLine(
        at(x, .02),
        at(x, .98),
        Paint()
          ..color = GlmArt.yellowCard
          ..strokeWidth = 2,
      );
    }
    for (var i = 0; i < 4; i++) {
      final p = at(x, .14 + i * .24);
      if (on) _arrowLine(c, [at(.3, .14 + i * .24), p], GlmTacticsArt.title, width: 2.5);
      c.drawCircle(p, 6, Paint()..color = GlmTacticsArt.mine);
    }
    c.drawCircle(at(.4, .5), 6, Paint()..color = GlmTacticsArt.theirs);
    // The flag.
    final pole = at(.52, -.1);
    c.drawLine(
      pole,
      pole + const Offset(0, -26),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
    c.drawRect(Rect.fromLTWH(pole.dx, pole.dy - 26, 16, on ? 11 : 0), Paint()..color = GlmTacticsArt.flag);
  }

  @override
  bool shouldRepaint(_TrapArt old) => old.on != on;
}
