part of 'clips.dart';

void _corner(_Scene s) {
  final u = s.u, claim = s.d['claim'] == true;
  const kickT = 1.0, keyT = 1.75;
  s.ground(roar: .2);
  // The flag at the corner, the taker by it.
  s.actors.add((
    300,
    () {
      s.c.drawLine(
        const Offset(965, 300),
        const Offset(965, 240),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3,
      );
      s.c.drawPath(
        Path()
          ..moveTo(965, 240)
          ..lineTo(992, 248 + math.sin(u * 8) * 3)
          ..lineTo(965, 258)
          ..close(),
        Paint()..color = s.l.gold,
      );
    },
  ));
  s.player(
    lerp(930, 952, seg(u, .4, kickT)),
    314,
    s.side,
    no: '7',
    run: u > .4 && u < kickT ? u * 12 : null,
    kick: seg(u, kickT - .15, kickT) * (1 - seg(u, kickT + .2, kickT + .5)),
  );
  // The box: jostling, then the jump.
  final jump = math.sin(seg(u, keyT - .25, keyT + .3) * math.pi);
  for (var i = 0; i < 6; i++) {
    final team = i.isEven ? s.side : s.other;
    final jostle = math.sin(u * 6 + i) * 6;
    final striker = i == 2;
    s.player(
      420 + i * 34.0 + jostle,
      340 + (i % 3) * 18.0,
      team,
      no: striker ? s.str('no') : '${i + 3}',
      front: !striker && team == s.other,
      lift: striker && !claim ? jump * 34 : (i == 3 ? jump * 20 : 0),
      arms: .2,
      face: 'angry',
    );
  }
  s.keeper(505, goalLine + 6, lift: claim ? jump * 36 : 0, arms: claim && u > keyT - .2 ? 1 : .6, face: claim && u > keyT ? 'joy' : 'idle');
  if (u < kickT) {
    s.ball(948, 318);
  } else {
    final t = seg(u, kickT, keyT);
    final p = bezier(const Offset(948, 318), const Offset(720, 250), const Offset(506, 344), t);
    if (u < keyT) {
      s.ball(p.dx, p.dy, z: math.sin(t * math.pi) * 120 + t * 60);
    } else if (claim) {
      s.ball(505, goalLine + 6, z: 120);
    } else {
      final r = seg(u, keyT, keyT + .7);
      s.ball(lerp(506, 520, r), lerp(344, goalLine - 6, r), z: 70 + r * 90);
    }
  }
  s.flush();
}

/// The fourth official's board: the number going off in red, the one coming on in green.
void _ledBoard(Canvas c, Offset at, String top, String bottom, double k, ClipLook l) {
  final r = Rect.fromCenter(center: at, width: 150 * k, height: 120 * k);
  c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(8 * k)), Paint()..color = const Color(0xFF101010));
  c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(8 * k)),
    Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  text(c, top, r.center - Offset(0, 28 * k), size: 44 * k, color: const Color(0xFFFF5252), family: 'BarlowCondensed');
  if (bottom.isNotEmpty) {
    text(c, bottom, r.center + Offset(0, 28 * k), size: 44 * k, color: const Color(0xFF69F0AE), family: 'BarlowCondensed');
  }
}

void _sub(_Scene s) {
  final u = s.u;
  s.ground();
  final board = seg(u, .2, .6, Curves.easeOutBack);
  // The player going off walks to the line, the one coming on waits; a high five; on he runs.
  final walk = seg(u, .6, 2.4, Curves.easeInOut);
  s.player(
    lerp(600, 515, walk),
    lerp(400, 500, walk),
    s.side,
    no: s.str('outNo'),
    run: walk > 0 && walk < 1 ? u * 7 : null,
    front: true,
    arms: seg(u, 2.3, 2.5) * (1 - seg(u, 2.7, 2.9)),
    face: 'idle',
  );
  final on = seg(u, 2.8, 4.6, Curves.easeIn);
  s.player(
    lerp(470, 380, on),
    lerp(510, 380, on),
    s.side,
    no: s.str('inNo'),
    run: on > 0 ? u * 12 : null,
    front: on < .1,
    arms: seg(u, 2.3, 2.5) * (1 - seg(u, 2.7, 2.9)),
    face: 'joy',
  );
  s.flush();
  if (board > 0) _ledBoard(s.c, const Offset(800, 300), s.str('outNo'), s.str('inNo'), board, s.l);
  if (u > 2.4 && u < 3.1) drawBurst(s.c, const Offset(492, 330), 'SLAP!', seg(u, 2.4, 3.1), size: 28, color: Colors.white);
}

void _injury(_Scene s) {
  final u = s.u;
  s.ground();
  final up = seg(u, 4.4, 5.0);
  s.player(
    500,
    440,
    s.side,
    no: s.str('no'),
    tilt: math.pi / 2 * (1 - up),
    front: true,
    face: up > .5 ? 'idle' : 'sad',
    arms: up >= 1 ? .5 : 0,
  );
  if (up < .5) s.actors.add((441, () => drawStars(s.c, const Offset(560, 410), u)));
  // The medic running on with his bag, the spray.
  final medic = seg(u, .8, 2.2, Curves.easeOut);
  s.actors.add((
    432,
    () {
      drawPlayer(
        s.c,
        lerp(900, 450, medic),
        432,
        shirt: const Color(0xFFF3F3F3),
        ink: Colors.red,
        shorts: const Color(0xFF2E7D32),
        front: true,
        run: medic < 1 ? u * 13 : null,
        face: 'worried',
      );
      final bag = Offset(lerp(900, 450, medic) + 18, 432 - 40);
      s.c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: bag, width: 22, height: 16), const Radius.circular(3)),
        Paint()..color = const Color(0xFFE53935),
      );
      s.c.drawLine(
        bag - const Offset(5, 0),
        bag + const Offset(5, 0),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3,
      );
      s.c.drawLine(
        bag - const Offset(0, 5),
        bag + const Offset(0, 5),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3,
      );
    },
  ));
  final spray = seg(u, 2.6, 3.8);
  if (spray > 0 && spray < 1) {
    s.actors.add((
      999,
      () {
        for (var i = 0; i < 9; i++) {
          final t = (spray * 3 + i / 9) % 1;
          s.c.drawCircle(
            Offset(470 + t * 50, 420 - t * 16 + math.sin(i * 1.3) * 8),
            4 + t * 10,
            Paint()..color = Colors.white.withValues(alpha: .7 * (1 - t)),
          );
        }
      },
    ));
  }
  s.flush();
  if (up >= 1) drawBurst(s.c, const Offset(560, 290), '👍', seg(u, 5.0, 5.6), size: 30, color: Colors.white);
}

void _coach(_Scene s, {required bool rant}) {
  final u = s.u;
  // The touchline: the technical area, the coach, two players by the line listening.
  s.ground();
  s.c.drawRect(const Rect.fromLTWH(0, 470, frameW, 92), Paint()..color = Colors.black.withValues(alpha: .18));
  final dashes = Paint()
    ..color = Colors.white70
    ..strokeWidth = 2;
  for (var x = 200.0; x < 800; x += 22) {
    s.c.drawLine(Offset(x, 470), Offset(x + 12, 470), dashes);
  }
  final gesture = math.sin(u * (rant ? 14 : 6));
  s.actors.add((
    520,
    () {
      drawPlayer(
        s.c,
        500,
        540,
        shirt: const Color(0xFF1E2A3A),
        ink: Colors.white,
        shorts: const Color(0xFF1E2A3A),
        front: true,
        armOut: .6 + .4 * gesture.abs(),
        arms: rant ? .6 : (gesture > .3 ? .4 : 0),
        face: rant ? 'angry' : 'idle',
        scale: 1.1,
      );
      if (rant) {
        // The megaphone and its waves.
        final m = Offset(500 + 40 * depth(540), 540 - 120 * depth(540));
        s.c.drawPath(
          Path()
            ..moveTo(m.dx, m.dy)
            ..lineTo(m.dx + 46, m.dy - 18)
            ..lineTo(m.dx + 46, m.dy + 18)
            ..close(),
          Paint()..color = const Color(0xFFE0E0E0),
        );
        for (var i = 0; i < 3; i++) {
          final r = 30.0 + ((u * 90 + i * 30) % 90);
          s.c.drawArc(
            Rect.fromCircle(center: m + const Offset(46, 0), radius: r),
            -.6,
            1.2,
            false,
            Paint()
              ..color = s.l.gold.withValues(alpha: 1 - r / 120)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      }
    },
  ));
  for (final (x, no) in [(330.0, '6'), (680.0, '10')]) {
    s.player(x, 440, s.side, no: no, front: true, face: rant ? 'worried' : 'idle', tilt: rant ? math.sin(u * 20) * .03 : 0);
    if (rant) {
      s.actors.add((
        441,
        () {
          for (var i = 0; i < 3; i++) {
            final t = (u * 1.5 + i / 3) % 1;
            s.c.drawCircle(
              Offset(x + 16 + i * 4, 440 - 104 * depth(440) + t * 30),
              3,
              Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 1 - t),
            );
          }
        },
      ));
    }
  }
  s.flush();
}

void _whistle(_Scene s) {
  final u = s.u;
  s.ground();
  s.referee(500, 450, arms: u > .5 && u < 1.6 ? .8 : 0, face: 'idle');
  s.flush();
  drawBurst(s.c, const Offset(560, 300), 'PEEEP!', seg(u, .5, 1.6), size: 44);
  // The board: the period, the score, the numbers.
  final k = seg(u, 1.0, 1.5, Curves.easeOutBack);
  if (k <= 0) return;
  final r = Rect.fromCenter(center: Offset(500, lerp(-120, 270, k)), width: 560, height: 230);
  s.c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(16)), Paint()..color = const Color(0xFF0B1220).withValues(alpha: .95));
  s.c.drawRRect(
    RRect.fromRectAndRadius(r, const Radius.circular(16)),
    Paint()
      ..color = s.l.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
  text(s.c, s.str('big'), r.topCenter + const Offset(0, 30), size: 26, color: s.l.gold);
  text(s.c, '${s.d['home'] ?? 0}  -  ${s.d['away'] ?? 0}', r.topCenter + const Offset(0, 78), size: 54, family: 'BarlowCondensed');
  final rows = (s.d['stats'] as List<dynamic>?) ?? const [];
  for (final (i, row) in rows.indexed) {
    final (label, h, a) = row as (String, int, int);
    final y = r.top + 128 + i * 24.0;
    text(s.c, '$h', Offset(r.left + 70, y), size: 18, family: 'BarlowCondensed');
    text(s.c, label, Offset(r.center.dx, y), size: 15, color: Colors.white70, weight: FontWeight.w600);
    text(s.c, '$a', Offset(r.right - 70, y), size: 18, family: 'BarlowCondensed');
  }
}

void _board(_Scene s) {
  final u = s.u;
  s.ground();
  final up = seg(u, .2, .6, Curves.easeOutBack);
  s.actors.add((
    470,
    () => drawPlayer(
      s.c,
      760,
      470,
      shirt: s.l.referee,
      ink: Colors.white,
      shorts: const Color(0xFF111111),
      front: true,
      arms: up,
      face: 'idle',
    ),
  ));
  s.flush();
  if (up > 0) _ledBoard(s.c, Offset(760, lerp(470, 300, up)), '+${s.d['plus'] ?? ''}', '', up * 1.2, s.l);
}

void _slip(_Scene s) {
  final u = s.u;
  const slipT = 1.0;
  s.ground();
  final run = seg(u, 0, slipT);
  final cx = lerp(360, 500, run), cy = lerp(470, 440, run);
  final slide = seg(u, slipT, slipT + 1.0, Curves.easeOut);
  s.player(
    cx + slide * 120,
    cy,
    s.side,
    no: s.str('no'),
    run: u < slipT ? u * 14 : null,
    tilt: -math.pi / 2 * seg(u, slipT, slipT + .25),
    lift: math.sin(seg(u, slipT, slipT + .3) * math.pi) * 30,
    front: false,
  );
  s.actors.add((cy + 2, () => drawSplash(s.c, Offset(cx + slide * 120, cy), seg(u, slipT + .1, slipT + .9))));
  // The defender who takes the ball and goes.
  final take = seg(u, slipT + .2, 3.6, Curves.easeIn);
  s.player(lerp(620, 300, take), lerp(430, 400, take), s.other, no: s.str('defNo'), run: u * 14, front: true, face: 'joy');
  s.ball(u < slipT + .2 ? cx + 16 : lerp(612, 292, take), u < slipT + .2 ? cy + 4 : lerp(436, 406, take));
  s.flush();
  drawBurst(s.c, Offset(cx + 120, cy - 100), 'SPLASH!', seg(u, slipT + .2, slipT + 1.4), size: 36, color: const Color(0xFF81D4FA));
}

// ---------------------------------------------------------------- the director's cutaways

/// The scorers' fans: a close-up of the stand jumping, scarves twirling, flares on the best tier.
void _crowd(_Scene s) {
  final u = s.u, flares = s.d['flares'] == true;
  final col = s.l.shirt(s.side);
  s.c.drawRect(const Rect.fromLTWH(0, 0, frameW, frameH), Paint()..color = Color.lerp(s.l.night, Colors.black, .2)!);
  final rnd = math.Random((s.d['v'] as num?)?.toInt() ?? 3);
  for (var row = 0; row < 4; row++) {
    final y = 160.0 + row * 120, scale = .9 + row * .25;
    for (var x = -20.0 + (row.isOdd ? 40 : 0); x < frameW + 40; x += 84 * scale) {
      final jump = (math.sin(u * 12 + x * .05 + row * 1.3) * .5 + .5) * 26 * scale;
      final shirt = rnd.nextDouble() > .15 ? col : Colors.white;
      drawPlayer(
        s.c,
        x,
        y + 40 * scale - jump,
        shirt: shirt,
        ink: s.l.ink(s.side),
        shorts: Color.lerp(shirt, Colors.black, .5),
        front: true,
        arms: .7 + .3 * math.sin(u * 9 + x),
        face: 'joy',
        scale: scale * 1.4,
        shadow: false,
      );
      if (rnd.nextDouble() > .7) {
        final scarf = Offset(x + 30 * scale, y - 110 * scale - jump);
        final a = u * 9 + x;
        s.c.drawLine(
          scarf,
          scarf + Offset(math.cos(a) * 40, math.sin(a) * 18),
          Paint()
            ..color = rnd.nextBool() ? col : Colors.white
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }
  if (flares) {
    for (final fx in [180.0, 520.0, 840.0]) {
      final f = Offset(fx, 130 + math.sin(u * 3 + fx) * 6);
      s.c.drawCircle(
        f,
        90,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0xFFFF5722).withValues(alpha: .65), const Color(0xFFFF5722).withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: f, radius: 90)),
      );
      s.c.drawCircle(f, 10, Paint()..color = const Color(0xFFFFF3E0));
      for (var i = 0; i < 6; i++) {
        final t = (u * .6 + i / 6) % 1;
        s.c.drawCircle(
          f + Offset(math.sin(i * 2.0 + u) * 30, -t * 140),
          26 + t * 30,
          Paint()..color = Colors.white.withValues(alpha: .12 * (1 - t)),
        );
      }
    }
  }
}
