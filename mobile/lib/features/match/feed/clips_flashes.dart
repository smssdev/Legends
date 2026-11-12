part of 'clips.dart';

/// The photographers' flashes after a goal.
void _flashes(_Scene s, double after) {
  final rnd = math.Random(8);
  s.actors.add((
    1000,
    () {
      for (var i = 0; i < 10; i++) {
        final at = rnd.nextDouble() * 4 + .2;
        final k = 1 - ((after - at).abs() * 8).clamp(0.0, 1.0);
        if (k > 0) {
          final p = Offset(rnd.nextDouble() * frameW, 30 + rnd.nextDouble() * 110);
          s.c.drawCircle(
            p,
            18 * k,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: k),
                  Colors.white.withValues(alpha: 0),
                ],
              ).createShader(Rect.fromCircle(center: p, radius: 18 * k)),
          );
        }
      }
    },
  ));
}

void _var(_Scene s) {
  final u = s.u;
  if (u < 4.2) {
    // The goal as it looked: compressed into 3 s, then the joy.
    final g = _Scene(s.c, s.l, s.side, s.d, u);
    _attack(g, outcome: 'goal');
  } else {
    s.ground(roar: .1);
    // The referee draws the screen in the air; the players wait.
    final draw = seg(u, 4.2, 5.0);
    s.referee(500, 420, arms: 0, armOut: .8, face: 'idle');
    for (var i = 0; i < 4; i++) {
      s.player(
        320 + i * 120.0,
        470 + (i.isOdd ? 20 : 0),
        i.isEven ? s.side : s.other,
        no: '${i * 3 + 4}',
        front: true,
        face: u < 6.4 ? 'worried' : (i.isEven ? 'sad' : 'joy'),
        arms: u >= 6.4 && i.isOdd ? 1 : 0,
      );
    }
    s.flush();
    if (draw > 0) {
      final r = Rect.fromCenter(center: const Offset(500, 300), width: 140 * draw, height: 90 * draw);
      s.c.drawRect(
        r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    // The VAR screen: checking, then the decision.
    final screen = seg(u, 5.0, 5.4, Curves.easeOutBack);
    if (screen > 0) {
      final r = Rect.fromCenter(center: const Offset(500, 250), width: 420 * screen, height: 200 * screen);
      s.c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = const Color(0xFF0B1220).withValues(alpha: .94));
      s.c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
        Paint()
          ..color = s.l.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      text(s.c, 'VAR', r.center - const Offset(0, 50), size: 40 * screen, color: s.l.gold, family: 'BarlowCondensed', letter: 6);
      if (u < 6.4) {
        final dots = '.' * (1 + (u * 3).floor() % 3);
        text(s.c, 'CHECKING$dots', r.center + const Offset(0, 20), size: 24 * screen, letter: 2);
      } else {
        if (s.d['reason'] == 'offside') {
          s.c.drawLine(
            r.centerLeft + const Offset(30, 74),
            r.centerRight + const Offset(-30, 74),
            Paint()
              ..color = const Color(0xFFFF5252)
              ..strokeWidth = 3,
          );
        }
        final k = seg(u, 6.4, 6.7, Curves.elasticOut);
        s.c.save();
        s.c.translate(r.center.dx, r.center.dy + 18);
        s.c.rotate(-.12);
        s.c.scale(.6 + .4 * k);
        s.c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 260, height: 64), const Radius.circular(8)),
          Paint()
            ..color = const Color(0xFFE53935)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6,
        );
        text(s.c, 'NO GOAL', Offset.zero, size: 44, color: const Color(0xFFE53935), family: 'BarlowCondensed', letter: 3);
        s.c.restore();
      }
    }
  }
}

void _penalty(_Scene s) {
  final u = s.u, aim = s.aim, scored = s.d['scored'] == true, saved = s.d['saved'] == true;
  const keyT = 4.05;
  final inNet = scored && u >= keyT;
  final netHit = Offset(500 + aim * 60, goalLine - 30);
  s.ground(roar: inNet ? 1 : .15, bulge: inNet ? netHit : null, give: inNet ? math.max(0, 1 - (u - keyT) * 1.5) : 0);
  // The referee points to the spot, then stands aside.
  final refOut = seg(u, 1.2, 2.0, Curves.easeInOut);
  s.referee(lerp(570, 700, refOut), lerp(430, 470, refOut), run: refOut > 0 && refOut < 1 ? u * 12 : null, armOut: u < 1.4 ? 1 : 0);
  // The keeper: bouncing on his line, waving his arms, then the dive.
  final dive = seg(u, 3.95, 4.25, Curves.easeOut);
  final dir = saved ? aim : -aim;
  final dance = u < 3.9 ? math.sin(u * 7) * 14 * seg(u, 2.0, 2.4) : 0.0;
  s.keeper(
    500 + dance + dir * 75 * dive,
    goalLine + 6,
    dive: dir * 1.4 * dive,
    lift: 24 * math.sin(dive * math.pi * .8),
    arms: u < 3.9 ? .5 + .5 * math.sin(u * 9).abs() : .9,
    face: u > keyT + .3 ? (saved ? 'joy' : 'sad') : 'angry',
  );
  // The taker: steps back, waits, runs up, strikes.
  final back = seg(u, 1.2, 2.4, Curves.easeInOut), runUp = seg(u, 3.4, 4.0, Curves.easeIn);
  final tx = lerp(lerp(505, 470, back), 492, runUp), ty = lerp(lerp(420, 500, back), 404, runUp);
  final after = u - keyT;
  s.player(
    tx,
    ty,
    s.side,
    no: s.str('no'),
    run: runUp > 0 && runUp < 1 ? u * 15 : (back > 0 && back < 1 ? u * 8 : null),
    kick: seg(u, 3.85, 4.0) * (1 - seg(u, 4.1, 4.5)),
    arms: after > .3 && scored ? 1 : (after > .4 && !scored ? 1 : 0),
    front: after > .6 && scored,
    face: scored ? 'joy' : 'sad',
  );
  if (u < 4.0) {
    s.ball(500, 392);
  } else {
    final to = scored
        ? Offset(netHit.dx, 30)
        : saved
        ? Offset(500 + aim * 75, 26)
        : Offset(500 + aim * 40, 140);
    final f = _flight(u, 4.0, keyT + .02, const Offset(500, 392), to);
    if (u < keyT + .02) {
      s.ball(f.x, f.y, z: f.z);
    } else if (saved) {
      final t = seg(u, keyT, keyT + .7, Curves.easeOut);
      s.ball(lerp(to.dx, to.dx + aim * 260, t), lerp(goalLine, goalLine + 60, t), z: 26 + math.sin(t * math.pi) * 40 - 26 * t);
    } else if (scored) {
      s.ball(to.dx, goalLine - 4, z: lerp(30, 0, seg(u, keyT, keyT + .6)));
    } else {
      s.ball(to.dx, goalLine - 10 * seg(u, keyT, keyT + .5), z: 140 + 60 * seg(u, keyT, keyT + .5));
    }
  }
  if (scored && after > 0) _flashes(s, after);
  s.flush();
  // The tension before the kick: a slow zoom of darkness at the edges.
  final tense = seg(u, 2.4, 3.6) * (1 - seg(u, 4.0, 4.3));
  if (tense > 0) {
    s.c.drawRect(
      const Rect.fromLTWH(0, 0, frameW, frameH),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: .55 * tense),
          ],
          stops: const [.55, 1],
        ).createShader(const Rect.fromLTWH(0, 0, frameW, frameH)),
    );
  }
}

void _freekick(_Scene s) {
  final u = s.u, aim = s.aim, scored = s.d['scored'] == true, saved = s.d['saved'] == true;
  const kickT = 2.3, keyT = 2.65;
  final netHit = Offset(500 + aim * 75, goalLine - 60);
  final inNet = scored && u >= keyT;
  s.ground(roar: inNet ? 1 : .15, bulge: inNet ? netHit : null, give: inNet ? math.max(0, 1 - (u - keyT) * 1.5) : 0);
  // The wall jumps as the kick is struck.
  final jump = math.sin(seg(u, kickT - .05, kickT + .45) * math.pi) * 26;
  for (var i = 0; i < 4; i++) {
    s.player(452 + i * 32.0, 352, s.other, front: true, lift: jump, face: 'worried', arms: 0);
  }
  final dive = seg(u, kickT + .1, keyT + .05, Curves.easeOut);
  s.keeper(
    520 + aim * 70 * dive,
    goalLine + 6,
    dive: aim * 1.3 * dive * (saved || scored ? 1 : .4),
    lift: 30 * math.sin(dive * math.pi * .85),
    face: u > keyT + .3 ? (scored ? 'sad' : 'joy') : 'surprise',
  );
  final run = seg(u, 1.6, kickT, Curves.easeIn);
  s.player(
    lerp(380, 438, run),
    lerp(500, 462, run),
    s.side,
    no: s.str('no'),
    run: run > 0 && run < 1 ? u * 14 : null,
    kick: seg(u, kickT - .15, kickT) * (1 - seg(u, kickT + .2, kickT + .6)),
    arms: u > keyT + .3 && scored ? 1 : 0,
    front: u > keyT + .6 && scored,
    face: 'joy',
  );
  const spot = Offset(452, 470);
  if (u < kickT) {
    s.ball(spot.dx, spot.dy);
  } else {
    // Curled over the wall into the corner (or over, or tipped away).
    final t = seg(u, kickT, keyT);
    final to = scored
        ? Offset(netHit.dx, goalLine + 2)
        : saved
        ? Offset(500 + aim * 85, goalLine + 2)
        : Offset(500 + aim * 60, goalLine - 4);
    final p = bezier(spot, Offset(500 - aim * 140, 330), to, t);
    final z =
        math.sin(t * math.pi * .9) * 110 +
        t *
            (scored
                ? 60
                : saved
                ? 64
                : 130);
    if (u < keyT) {
      s.ball(p.dx, p.dy, z: z);
    } else if (saved) {
      final r = seg(u, keyT, keyT + .7, Curves.easeOut);
      s.ball(lerp(to.dx, to.dx + aim * 160, r), lerp(goalLine, goalLine - 10, r), z: 64 + 60 * r);
    } else if (scored) {
      s.ball(to.dx, goalLine - 6, z: lerp(60, 0, seg(u, keyT, keyT + .7)));
    } else {
      s.ball(to.dx, goalLine - 8, z: 130 + 70 * seg(u, keyT, keyT + .6));
    }
  }
  if (scored && u > keyT) _flashes(s, u - keyT);
  s.flush();
}

void _card(_Scene s) {
  final u = s.u, red = s.d['type'] == 'red', drama = s.str('drama');
  const contact = 1.5, cardT = 3.4;
  s.ground(roar: seg(u, contact, contact + .3) * .3);
  final victim = s.other, offender = s.side;
  // The victim dribbling across, then the tackle and the tumble.
  final run = seg(u, 0, contact);
  final vx = lerp(360, 520, run), vy = lerp(470, 440, run);
  final fall = seg(u, contact, contact + .8, Curves.easeOut);
  final roll = drama == 'flying' ? fall * math.pi * 2.2 : fall * math.pi * .5;
  s.player(
    vx + fall * 40,
    vy,
    victim,
    no: s.str('victimNo'),
    run: u < contact ? u * 14 : null,
    tilt: roll,
    lift: math.sin(fall * math.pi) * (drama == 'flying' ? 60 : 24),
    front: true,
    face: u > contact ? 'sad' : 'idle',
  );
  if (fall >= 1 && u < 5) s.actors.add((vy + 1, () => drawStars(s.c, Offset(vx + 40 + 20, vy - 30), u)));
  if (u < contact + .1) s.ball(vx + 14, vy + 4);
  // The offender: the slide (or the two-footed lunge), then on his feet protesting.
  final slideIn = seg(u, contact - .5, contact, Curves.easeIn);
  final up = seg(u, contact + 1.0, contact + 1.4);
  final ox = lerp(640, vx - 6, slideIn), oy = lerp(500, vy + 10, slideIn);
  s.player(
    ox,
    oy,
    offender,
    no: s.str('no'),
    run: slideIn < 1 ? u * 14 : null,
    tilt: (drama == 'flying' ? -.9 : -1.25) * slideIn * (1 - up),
    lift: drama == 'flying' ? math.sin(slideIn * math.pi) * 40 : 0,
    armOut: u > cardT ? .9 + .1 * math.sin(u * 10) : 0,
    arms: u > cardT && !red ? .3 : 0,
    front: u > contact + 1.2,
    face: u > cardT ? 'angry' : 'surprise',
  );
  if (drama == 'flying' && slideIn > .8 && u < contact + .4) {
    s.actors.add((999, () => drawBurst(s.c, Offset(vx, vy - 120), 'OUCH!', seg(u, contact, contact + .9), color: const Color(0xFFFF8A65))));
  }
  // The crowd around the referee, pointing, when the server tells it so.
  final gather = seg(u, 2.0, 3.0, Curves.easeOut);
  if (drama == 'crowd' || drama == 'brawl') {
    for (var i = 0; i < 4; i++) {
      final a = i * 1.7 + 1;
      s.player(
        lerp(i.isEven ? 300 : 720, 560 + math.cos(a) * 70, gather),
        lerp(560, 450 + math.sin(a) * 26, gather),
        i.isEven ? offender : victim,
        no: '${i * 2 + 5}',
        run: gather < 1 ? u * 13 : null,
        armOut: gather,
        front: true,
        face: 'angry',
      );
    }
  }
  if (drama == 'brawl' && u > 2.4 && u < 3.3) s.actors.add((998, () => drawDust(s.c, const Offset(560, 400), u, size: 56)));
  // The referee: running in, the card held high.
  final refIn = seg(u, 1.6, 2.9, Curves.easeOut);
  final cardUp = u > cardT - .25;
  s.referee(
    lerp(760, 590, refIn),
    lerp(380, 452, refIn),
    run: refIn > 0 && refIn < 1 ? u * 13 : null,
    hold: cardUp ? (red ? const Color(0xFFE53935) : const Color(0xFFFFD600)) : null,
    face: 'angry',
  );
  // A red card: the long walk off.
  if (red && u > 4.8) {
    s.actors.removeWhere((a) => a.$1 == oy);
    final walk = seg(u, 4.8, 6.6);
    s.player(lerp(ox, 980, walk), lerp(oy, 520, walk), offender, no: s.str('no'), run: u * 6, front: false);
  }
  s.flush();
}

void _foul(_Scene s) {
  final u = s.u, dive = s.str('drama') == 'dive';
  const contact = 1.5;
  s.ground(roar: .1);
  final run = seg(u, 0, contact);
  final vx = lerp(380, 540, run), vy = lerp(470, 440, run);
  final fall = seg(u, contact, contact + (dive ? 1.0 : .7), Curves.easeOut);
  // A dive: a leap, a twirl in the air, the clutched shin; a tackle: down and rolling.
  s.player(
    vx + fall * (dive ? 70 : 34),
    vy,
    s.other,
    no: s.str('victimNo'),
    run: u < contact ? u * 14 : null,
    tilt: fall * (dive ? math.pi * 2.5 : math.pi * .5),
    lift: math.sin(fall * math.pi) * (dive ? 80 : 20),
    front: true,
    face: u > contact ? 'sad' : 'idle',
  );
  if (dive && fall >= 1) {
    s.actors.add((
      999,
      () => drawBurst(s.c, Offset(vx + 70, vy - 110), '!?', seg(u, contact + 1.0, contact + 2.2), size: 34, color: Colors.white),
    ));
  }
  if (!dive && fall >= 1 && u < 4.5) s.actors.add((vy + 1, () => drawStars(s.c, Offset(vx + 54, vy - 26), u)));
  if (u < contact + .1) s.ball(vx + 14, vy + 4);
  final slideIn = seg(u, contact - .5, contact, Curves.easeIn);
  s.player(
    lerp(650, vx - (dive ? 40 : 6), slideIn),
    lerp(500, vy + 12, slideIn),
    s.side,
    no: s.str('no'),
    run: slideIn < 1 ? u * 14 : null,
    tilt: (dive ? -.2 : -1.2) * slideIn * (1 - seg(u, contact + 1, contact + 1.4)),
    armOut: dive && u > contact + .5 ? 1 : 0,
    front: u > contact + 1.0,
    face: dive ? 'surprise' : 'worried',
  );
  // The referee's whistle, his arm pointing.
  s.referee(
    lerp(740, 640, seg(u, 1.2, 2.2)),
    lerp(390, 430, seg(u, 1.2, 2.2)),
    run: u > 1.2 && u < 2.2 ? u * 12 : null,
    armOut: u > 2.2 ? 1 : 0,
  );
  s.actors.add((999, () => drawBurst(s.c, const Offset(690, 300), 'PEEP!', seg(u, 2.0, 2.9), size: 34)));
  s.flush();
}

void _offside(_Scene s, {required bool trap}) {
  final u = s.u;
  const keyT = 1.5;
  s.ground(roar: .1);
  // The back line: four defenders, stepping up together for the trap.
  final step = trap ? seg(u, .7, 1.3, Curves.easeOut) : 0.0;
  final lineY = lerp(400, 360, step);
  for (var i = 0; i < 4; i++) {
    s.player(
      330 + i * 110.0,
      lineY + (i.isOdd ? 6 : 0),
      s.other,
      front: true,
      run: step > 0 && step < 1 ? u * 12 : null,
      arms: trap && u > keyT ? 1 : 0,
      face: trap && u > keyT ? 'joy' : 'idle',
    );
  }
  // The pass in behind and the attacker running onto it.
  final runT = seg(u, .3, 1.3, Curves.easeOut);
  final ax = lerp(560, 520, runT), ay = lerp(470, 335, runT);
  s.player(
    ax,
    ay,
    s.side,
    no: s.str('no'),
    run: runT < 1 ? u * 15 : null,
    armOut: u > keyT + .5 ? 1 : 0,
    front: u > keyT + .5,
    face: 'angry',
  );
  final ballT = seg(u, .5, 1.25);
  s.ball(lerp(420, ax + 6, ballT), lerp(520, ay + 4, ballT), z: math.sin(ballT * math.pi) * 40);
  // The assistant on the line, his flag up.
  final flag = u > keyT;
  s.actors.add((
    470,
    () {
      drawPlayer(
        s.c,
        930,
        470,
        shirt: s.l.referee,
        ink: Colors.white,
        shorts: const Color(0xFF111111),
        front: true,
        arms: flag ? 1 : 0,
        face: 'idle',
      );
      final hand = Offset(930 + 26 * depth(470), 470 - (flag ? 122 : 50) * depth(470));
      s.c.drawLine(
        hand,
        hand + Offset(0, flag ? -40 : 30),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3,
      );
      final cloth = hand + Offset(0, flag ? -40 : 30);
      final wave = flag ? math.sin(u * 18) * 6 : 0.0;
      s.c.drawPath(
        Path()
          ..moveTo(cloth.dx, cloth.dy)
          ..lineTo(cloth.dx + 24, cloth.dy + 6 + wave)
          ..lineTo(cloth.dx, cloth.dy + 16)
          ..close(),
        Paint()..color = const Color(0xFFFF6D00),
      );
    },
  ));
  s.flush();
  // The broadcast's offside line, once flagged.
  if (flag) {
    final k = seg(u, keyT, keyT + .3);
    final pen = Paint()
      ..color = const Color(0xFFFFD600).withValues(alpha: .9 * k)
      ..strokeWidth = 3;
    for (var x = 0.0; x < frameW; x += 24) {
      s.c.drawLine(Offset(x, lineY + 2), Offset(x + 14, lineY + 2), pen);
    }
    s.c.drawCircle(
      Offset(ax, ay),
      22 * k,
      Paint()
        ..color = const Color(0xFFFF5252).withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
