import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art.dart';

/// [Sprint 44 B1–B3] The app's cartoon clips, each a function of the scene's own clock ([u], seconds; story.dart's
/// sceneTime gives each length and key moment) and the server's data for it (who, which way, how it is told). They
/// only draw: what happened is the server's (MomentClock), as on the web (art.ts). A thing standing nearer the camera
/// (a larger y) is drawn after, so it stands in front.
typedef Actor = (double y, void Function() draw);

class ClipPainter extends CustomPainter {
  ClipPainter({required this.scene, required this.data, required this.side, required this.u, required this.look});

  final String scene, side;
  final Map<String, Object?> data;
  final double u;
  final ClipLook look;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    fitFrame(canvas, size);
    final c = canvas;
    final paint = _scenes[scene];
    if (paint != null) paint(_Scene(c, look, side, data, u));
    if (look.rain && !['studio', 'coachReact', 'crowd'].contains(scene)) drawRain(c, u, heavy: scene == 'slip' ? 1.6 : 1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ClipPainter old) => old.u != u || old.scene != scene;
}

/// One frame of a scene: the canvas, the look, the attacking side, the data, the clock, and its actors.
class _Scene {
  _Scene(this.c, this.l, this.side, this.d, this.u);

  final Canvas c;
  final ClipLook l;
  final String side;
  final Map<String, Object?> d;
  final double u;
  final List<Actor> actors = [];

  String get other => side == 'home' ? 'away' : 'home';
  String str(String k) => '${d[k] ?? ''}';
  int get v => (d['v'] as num?)?.toInt() ?? 7;

  /// Which way the shot goes (-1 left, 1 right), from the server's lane or the scene's seed.
  double get aim => d['lane'] == 'left'
      ? -1
      : d['lane'] == 'right'
      ? 1
      : (v % 2 == 0 ? -1 : 1);

  void player(
    double x,
    double y,
    String team, {
    String no = '',
    double? run,
    double kick = 0,
    double arms = 0,
    double tilt = 0,
    double lift = 0,
    bool front = false,
    Color? hold,
    String face = 'idle',
    double armOut = 0,
  }) => actors.add((
    y,
    () => drawPlayer(
      c,
      x,
      y,
      shirt: l.shirt(team),
      ink: l.ink(team),
      no: no,
      run: run,
      kick: kick,
      arms: arms,
      tilt: tilt,
      lift: lift,
      front: front,
      hold: hold,
      face: face,
      armOut: armOut,
    ),
  ));

  void keeper(double x, double y, {double dive = 0, double lift = 0, double arms = .6, String face = 'idle'}) => actors.add((
    y,
    () => drawPlayer(
      c,
      x,
      y,
      shirt: l.keeper,
      ink: Colors.black,
      shorts: Color.lerp(l.keeper, Colors.black, .45),
      front: true,
      gloves: true,
      arms: arms,
      tilt: dive,
      lift: lift,
      face: face,
      scale: .95,
    ),
  ));

  void referee(double x, double y, {double? run, Color? hold, double arms = 0, double armOut = 0, String face = 'idle'}) => actors.add((
    y,
    () => drawPlayer(
      c,
      x,
      y,
      shirt: l.referee,
      ink: Colors.white,
      shorts: const Color(0xFF111111),
      front: true,
      run: run,
      hold: hold,
      arms: arms,
      armOut: armOut,
      face: face,
    ),
  ));

  void ball(double x, double y, {double z = 0}) => actors.add((y + .1, () => drawBall(c, x, y, z: z, spin: u * 12)));

  void ground({double roar = 0, Offset? bulge, double give = 0}) {
    drawGround(c, l, u, roar: roar, goal: bulge == null);
    if (bulge != null) drawGoal(c, l, bulge: bulge, give: give);
  }

  void flush() {
    actors.sort((a, b) => a.$1.compareTo(b.$1));
    for (final a in actors) {
      a.$2();
    }
    actors.clear();
  }
}

/// A shot from [from] to [to] (on the goal plane: x, height above the line), flying over [a, b] seconds.
({double x, double y, double z}) _flight(double u, double a, double b, Offset from, Offset to, {double arc = 0}) {
  final t = seg(u, a, b);
  return (x: lerp(from.dx, to.dx, t), y: lerp(from.dy, goalLine + 2, t), z: lerp(0, to.dy, t) + math.sin(t * math.pi) * arc);
}

final Map<String, void Function(_Scene)> _scenes = {
  // ---- A goal (6.0 s, the ball in at 3.0): a pass, the run, the defender too late, the strike, the net, the joy.
  'goal': (s) => _attack(s, outcome: 'goal'),
  // ---- A save (5.4 s, at 2.9): the shot, the keeper flying to it.
  'save': (s) => _attack(s, outcome: 'save'),
  // ---- A miss (5.0 s, at 2.9): wide, over the bar, or the post.
  'miss': (s) => _attack(s, outcome: 'miss'),
  // ---- Blocked (4.8 s, at 2.6): a defender's slide in front of the shot.
  'blocked': (s) => _attack(s, outcome: 'blocked'),
  // ---- Off the line (4.2 s, at 2.4): past the keeper, and a defender sliding in to kick it off the line.
  'clearance': (s) => _attack(s, outcome: 'clearance', shotAt: 1.6),
  // ---- A goal ruled out (8.2 s, no goal at 6.4): the goal, the joy, the referee's square, the screen, NO GOAL.
  'var': _var,
  'penalty': _penalty,
  'freekick': _freekick,
  'card': _card,
  'foul': _foul,
  'offside': (s) => _offside(s, trap: false),
  'trap': (s) => _offside(s, trap: true),
  'corner': _corner,
  'sub': _sub,
  'injury': _injury,
  'coach': (s) => _coach(s, rant: false),
  'rant': (s) => _coach(s, rant: true),
  'whistle': _whistle,
  'board': _board,
  'slip': _slip,
  // ---- The director's cutaways.
  'crowd': _crowd,
  'coachReact': _coachReact,
  'meltdown': _meltdown,
  'brawl': _brawl,
  'tunnel': _tunnel,
  'handshake': _handshake,
  'studio': _studio,
};

/// The attacking move every shot scene shares: a pass (when there was a passer), the striker's run with the ball, a
/// defender chasing, then the strike at [shotAt] and what came of it.
void _attack(_Scene s, {required String outcome, double? shotAt}) {
  final u = s.u, aim = s.aim, header = s.d['quality'] == 'header';
  final kickT = shotAt ?? (outcome == 'blocked' ? 2.2 : 2.5);
  final keyT = outcome == 'goal'
      ? 3.0
      : outcome == 'blocked'
      ? 2.6
      : outcome == 'clearance'
      ? 2.4
      : 2.9;
  final scored = outcome == 'goal' && u >= keyT;
  final netHit = Offset(500 + aim * 62, goalLine - 22);
  s.ground(
    roar: scored ? 1 : seg(u, keyT - .6, keyT) * .3,
    bulge: scored ? netHit : null,
    give: scored ? math.max(0, 1 - (u - keyT) * 1.5) : 0,
  );

  final passNo = s.str('passNo');
  // The striker: from the near right, onto the ball, to the edge of the box.
  final runIn = seg(u, 0, kickT, Curves.easeInOut);
  var sx = lerp(600, 470 - aim * 10, runIn), sy = lerp(545, 405, runIn);
  // The defender chasing him, sliding in at the end.
  final dIn = seg(u, .3, kickT + .1);
  final dx = lerp(320, sx - 40, dIn), dy = lerp(470, sy + 8, dIn);
  final slide = seg(u, kickT - .45, kickT - .05);
  if (outcome == 'blocked') {
    final bx = lerp(380, 470, seg(u, 1.2, 2.3, Curves.easeOut)), by = lerp(360, 360, 0);
    s.player(bx, by, s.other, no: s.str('defNo'), run: u < 2.3 ? u * 14 : null, tilt: seg(u, 2.0, 2.4) * -1.2, front: true, face: 'angry');
  } else {
    s.player(dx, dy, s.other, no: s.str('defNo'), run: slide < 1 && u < kickT ? u * 13 : null, tilt: slide * -1.1, front: false);
  }
  if (passNo.isNotEmpty) {
    s.player(
      lerp(300, 330, seg(u, 0, 1)),
      lerp(470, 480, seg(u, 0, 1)),
      s.side,
      no: passNo,
      run: u < 1 ? u * 10 : null,
      kick: seg(u, .55, .75) * (1 - seg(u, .75, 1.0)),
    );
  }

  // The keeper: set on his line, then diving (the right way for a save, too late or the wrong way otherwise).
  final diveDir = outcome == 'save'
      ? aim
      : outcome == 'goal'
      ? (s.v % 3 == 0 ? aim : -aim)
      : aim;
  final diveT = seg(u, kickT + .12, keyT + .05, Curves.easeOut);
  final down = seg(u, keyT + .3, keyT + .9);
  s.keeper(
    500 + diveDir * 70 * diveT,
    goalLine + 6,
    dive: diveDir * 1.35 * diveT,
    lift: 26 * math.sin(diveT * math.pi * .85) * (1 - down),
    arms: .9,
    face: outcome == 'goal' && u > keyT
        ? 'sad'
        : outcome == 'save' && u > keyT + .5
        ? 'joy'
        : 'surprise',
  );

  // The ball.
  if (u < kickT) {
    final bp = passNo.isNotEmpty && u < 1.0 ? lerpO(const Offset(332, 488), Offset(sx, sy + 6), seg(u, .7, 1.0)) : Offset(sx + 6, sy + 6);
    s.ball(bp.dx, bp.dy, z: header ? 0 : 0);
  } else {
    final from = Offset(sx + 6, sy + 6);
    switch (outcome) {
      case 'goal':
        final f = _flight(u, kickT, keyT, from, Offset(netHit.dx, 30 + (s.v % 3) * 12), arc: 14);
        // In the net: behind the line, dropping to the grass inside the goal.
        if (u < keyT) {
          s.ball(f.x, f.y, z: f.z);
        } else if (u < keyT + 1.2) {
          s.ball(f.x, goalLine - 14 * seg(u, keyT, keyT + .2), z: lerp(f.z, 0, seg(u, keyT, keyT + .6, Curves.bounceOut)));
        }
        _trail(s, u, kickT, keyT, (t) => _flight(t, kickT, keyT, from, Offset(netHit.dx, 30 + (s.v % 3) * 12), arc: 14));
      case 'save':
        final f = _flight(u, kickT, keyT, from, Offset(500 + aim * 75, 34), arc: 10);
        if (u < keyT) {
          s.ball(f.x, f.y, z: f.z);
        } else {
          // Parried away, out for a corner or back into the box.
          final t = seg(u, keyT, keyT + .7, Curves.easeOut);
          s.ball(
            lerp(500 + aim * 75, 500 + aim * 330, t),
            lerp(goalLine + 2, goalLine + 40, t),
            z: 34 + math.sin(t * math.pi) * 40 - t * 34,
          );
        }
        if (s.d['drama'] == 'double' && u > 3.4) _rebound(s, u, aim);
      case 'miss':
        final how = s.str('how');
        final to = switch (how) {
          'over' => Offset(500 + aim * 40, 150),
          'post' => Offset(500 + aim * 95, 40),
          _ => Offset(500 + aim * 140, 16),
        };
        final f = _flight(u, kickT, keyT, from, to, arc: how == 'over' ? 20 : 8);
        if (u < keyT) {
          s.ball(f.x, f.y, z: f.z);
        } else if (how == 'post') {
          final t = seg(u, keyT, keyT + .8, Curves.easeOut);
          s.ball(lerp(to.dx, to.dx - aim * 160, t), lerp(goalLine + 2, goalLine + 60, t), z: lerp(to.dy, 0, t));
        } else {
          final t = seg(u, keyT, keyT + .6);
          s.ball(lerp(to.dx, to.dx + (to.dx - 500) * .3, t), goalLine - 10 * t, z: to.dy + t * (how == 'over' ? 90 : 10));
        }
        if (how == 'post') s.actors.add((999, () => drawBurst(s.c, Offset(500 + aim * 95, barY + 50), 'BOING!', seg(u, keyT, keyT + 1.0))));
      case 'blocked':
        final t = seg(u, kickT, keyT);
        if (u < keyT) {
          s.ball(lerp(from.dx, 465, t), lerp(from.dy, 368, t), z: 8 * t);
        } else {
          final r = seg(u, keyT, keyT + .8, Curves.easeOut);
          s.ball(lerp(465, 465 + aim * 260, r), lerp(368, 470, r), z: math.sin(r * math.pi) * 60);
        }
        s.actors.add((
          999,
          () => drawBurst(s.c, const Offset(470, 300), 'BLOCK!', seg(u, keyT, keyT + .9), color: const Color(0xFFFF8A65)),
        ));
      case 'clearance':
        // Rolling toward the empty goal, a defender running back to the line.
        final roll = seg(u, kickT, keyT + .05);
        final bx = lerp(from.dx, 500 + aim * 30, roll), by = lerp(from.dy, goalLine + 4, roll);
        final defT = seg(u, kickT, keyT, Curves.easeIn);
        s.player(
          lerp(500 - aim * 90, bx - aim * 22, defT),
          lerp(goalLine + 4, goalLine + 6, defT),
          s.other,
          no: s.str('defNo'),
          run: u < keyT ? u * 16 : null,
          tilt: seg(u, keyT - .25, keyT) * aim * 1.0,
          kick: seg(u, keyT - .1, keyT),
          front: true,
          face: 'angry',
        );
        if (u < keyT) {
          s.ball(bx, by);
        } else {
          final r = seg(u, keyT, keyT + .9, Curves.easeOut);
          s.ball(lerp(bx, bx - aim * 420, r), lerp(by, by + 40, r), z: math.sin(r * math.pi) * 120);
          s.actors.add((999, () => drawBurst(s.c, Offset(bx, goalLine - 70), 'WOW!', seg(u, keyT, keyT + 1))));
        }
    }
  }

  // The striker: the strike, then what came of it (the joy, his hands on his head).
  final after = u - keyT;
  if (outcome == 'goal' && after > 0) {
    // Running at the camera, then the knee slide, the teammates piling on.
    final r = seg(after, .2, 1.4, Curves.easeOut);
    sx = lerp(sx, 420 + aim * 30, r);
    sy = lerp(sy, 500, r);
    final kneel = seg(after, 1.2, 1.5);
    s.player(
      sx,
      sy,
      s.side,
      no: s.str('no'),
      run: r < 1 ? u * 15 : null,
      arms: math.min(1, after * 2),
      tilt: -kneel * .35,
      front: after > .5,
      face: 'joy',
      lift: -kneel * 18,
    );
    for (var i = 0; i < 3; i++) {
      final m = seg(after, 1.4 + i * .25, 2.4 + i * .25, Curves.easeOut);
      if (m > 0) {
        s.player(
          lerp(300 + i * 240, sx + (i - 1) * 40, m),
          lerp(560, sy + 12, m),
          s.side,
          no: '${(s.v + i * 3) % 11 + 2}',
          run: m < 1 ? u * 14 : null,
          arms: m,
          front: true,
          face: 'joy',
        );
      }
    }
    _flashes(s, after);
  } else {
    final dejected = (outcome == 'miss' || outcome == 'save' || outcome == 'clearance') && after > .5;
    s.player(
      sx,
      sy,
      s.side,
      no: s.str('no'),
      run: u < kickT - .1 ? u * 14 : null,
      kick: seg(u, kickT - .15, kickT) * (1 - seg(u, kickT + .1, kickT + .5)),
      arms: dejected ? 1 : 0,
      lift: header && (u - kickT).abs() < .3 ? 24 : 0,
      face: dejected ? 'sad' : 'idle',
    );
  }
  s.flush();
}

void _trail(_Scene s, double u, double a, double b, ({double x, double y, double z}) Function(double) at) {
  if (u < a || u > b + .15) return;
  final pts = <Offset>[];
  for (var i = 0; i < 8; i++) {
    final t = math.max(a, math.min(u, b) - (7 - i) * .03);
    final p = at(t);
    pts.add(Offset(p.x, p.y - 7 * depth(p.y) - p.z * depth(p.y)));
  }
  s.actors.add((p0(pts), () => drawTrail(s.c, pts, Colors.white)));
}

double p0(List<Offset> pts) => 998;

/// A second shot after a parry, saved again (drama: double).
void _rebound(_Scene s, double u, double aim) {
  final t = seg(u, 3.4, 3.9);
  s.player(
    lerp(560 + aim * 80, 520 + aim * 60, t),
    lerp(470, 380, t),
    s.side,
    no: s.str('passNo').isEmpty ? '9' : s.str('passNo'),
    run: u < 3.85 ? u * 15 : null,
    kick: seg(u, 3.75, 3.9),
  );
  if (u > 3.9) {
    final f = seg(u, 3.9, 4.2);
    s.ball(lerp(520 + aim * 60, 500 - aim * 40, f), lerp(380, goalLine + 4, f), z: f * 20);
    s.actors.add((999, () => drawBurst(s.c, const Offset(500, 180), 'DOUBLE SAVE!', seg(u, 4.2, 5.2), size: 56)));
  }
}

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

/// A coach's close-up in his look (C1 to C3) and his mood: joy, anger, worry, sorrow.
void _coachReact(_Scene s, {String? moodOverride}) {
  final u = s.u, side = s.str('side').isEmpty ? s.side : s.str('side');
  final mood = moodOverride ?? s.str('mood');
  final suit = switch (s.str('look')) {
    'C2' => const Color(0xFF3A2A1A),
    'C3' => const Color(0xFF263238),
    _ => const Color(0xFF15233A),
  };
  s.c.drawRect(
    const Rect.fromLTWH(0, 0, frameW, frameH),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(s.l.night, s.l.shirt(side), .25)!, s.l.night],
      ).createShader(const Rect.fromLTWH(0, 0, frameW, frameH)),
  );
  // The dugout behind him.
  s.c.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(80, 120, 840, 260), const Radius.circular(40)),
    Paint()..color = Colors.white.withValues(alpha: .06),
  );
  for (var i = 0; i < 6; i++) {
    s.c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(130 + i * 130.0, 290, 100, 60), const Radius.circular(10)),
      Paint()..color = s.l.shirt(side).withValues(alpha: .5),
    );
  }
  final joy = mood == 'joy' || mood == 'cheer';
  final hop = joy ? (math.sin(u * 12).abs() * 40) : 0.0;
  final shake = mood == 'angry' ? math.sin(u * 30) * 4 : 0.0;
  drawPlayer(
    s.c,
    500 + shake,
    700 - hop,
    shirt: suit,
    ink: Colors.white,
    shorts: suit,
    front: true,
    arms: joy
        ? 1
        : mood == 'worried'
        ? .85
        : 0,
    armOut: mood == 'angry' ? .9 : 0,
    face: mood,
    scale: 3.2,
    shadow: false,
  );
  // The suit's shirt, lapels and tie in his club's colour (the body's top is 88 × 2.7 above his feet).
  final k = depth(700 - hop) * 3.2, neck = Offset(500 + shake, 700 - hop - 88 * k);
  s.c.drawPath(
    Path()
      ..moveTo(neck.dx - 10 * k, neck.dy)
      ..lineTo(neck.dx, neck.dy + 22 * k)
      ..lineTo(neck.dx + 10 * k, neck.dy)
      ..close(),
    Paint()..color = Colors.white,
  );
  s.c.drawPath(
    Path()
      ..moveTo(neck.dx - 3 * k, neck.dy + 2 * k)
      ..lineTo(neck.dx + 3 * k, neck.dy + 2 * k)
      ..lineTo(neck.dx + 4 * k, neck.dy + 26 * k)
      ..lineTo(neck.dx, neck.dy + 31 * k)
      ..lineTo(neck.dx - 4 * k, neck.dy + 26 * k)
      ..close(),
    Paint()..color = s.l.shirt(side),
  );
  final lapel = Paint()
    ..color = Color.lerp(suit, Colors.black, .35)!
    ..strokeWidth = 2.5 * k
    ..strokeCap = StrokeCap.round;
  s.c.drawLine(neck + Offset(-11 * k, 0), neck + Offset(-2 * k, 26 * k), lapel);
  s.c.drawLine(neck + Offset(11 * k, 0), neck + Offset(2 * k, 26 * k), lapel);
  // His anger's steam, his worry's sweat.
  if (mood == 'angry') {
    for (var i = 0; i < 3; i++) {
      final t = (u * 1.5 + i / 3) % 1;
      s.c.drawCircle(Offset(470 + i * 30, 120 - t * 80), 14 + t * 20, Paint()..color = Colors.white.withValues(alpha: .4 * (1 - t)));
    }
  }
  if (mood == 'worried' || mood == 'sad') {
    for (var i = 0; i < 2; i++) {
      final t = (u * 1.2 + i / 2) % 1;
      s.c.drawCircle(Offset(560 + i * 14, 210 + t * 40), 6, Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 1 - t));
    }
  }
}

void _meltdown(_Scene s) {
  final u = s.u;
  _coachReact(s, moodOverride: 'angry');
  // The jacket thrown, the water bottle kicked.
  final t = seg(u, .4, 1.6, Curves.easeOut);
  if (t > 0) {
    s.c.save();
    s.c.translate(lerp(560, 860, t), lerp(260, 120, t) + t * t * 160);
    s.c.rotate(t * 6);
    s.c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 90, height: 60), const Radius.circular(12)),
      Paint()..color = const Color(0xFF15233A),
    );
    s.c.restore();
  }
  final b = seg(u, 1.0, 2.0, Curves.easeOut);
  if (b > 0) {
    s.c.save();
    s.c.translate(lerp(420, 120, b), lerp(500, 300, b) + b * b * 200);
    s.c.rotate(-b * 9);
    s.c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 22, height: 54), const Radius.circular(6)),
      Paint()..color = const Color(0xFF4FC3F7),
    );
    s.c.restore();
  }
  drawBurst(s.c, const Offset(250, 140), '#@!', seg(u, .2, 1.6), size: 44, color: const Color(0xFFFF8A65));
}

void _brawl(_Scene s) {
  s.ground(roar: .3);
  drawDust(s.c, const Offset(500, 400), s.u, size: 120);
  s.referee(500 + math.sin(s.u * 10) * 60, 500, run: s.u * 14, armOut: 1, face: 'angry');
  s.flush();
}

void _tunnel(_Scene s) {
  final u = s.u;
  s.c.drawRect(const Rect.fromLTWH(0, 0, frameW, frameH), Paint()..color = Color.lerp(s.l.night, Colors.black, .3)!);
  // The tunnel's mouth, lit, and the players walking into it.
  s.c.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(380, 160, 240, 260), const Radius.circular(120)),
    Paint()..color = const Color(0xFF05080D),
  );
  s.c.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(380, 160, 240, 260), const Radius.circular(120)),
    Paint()
      ..color = s.l.gold.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5,
  );
  text(s.c, 'LEGENDS', const Offset(500, 140), size: 22, color: s.l.gold, letter: 5);
  s.c.drawRect(const Rect.fromLTWH(0, 420, frameW, 142), Paint()..color = s.l.grassDark);
  for (var i = 0; i < 6; i++) {
    final t = seg(u, i * .25, 2.6 + i * .1);
    final team = i.isEven ? 'home' : 'away';
    final y = lerp(560, 430, t);
    drawPlayer(
      s.c,
      lerp(i.isEven ? 330 : 670, 500 + (i.isEven ? -30 : 30), t),
      y,
      shirt: s.l.shirt(team),
      ink: s.l.ink(team),
      no: '${i * 2 + 3}',
      run: u * 7,
      scale: lerp(1.5, .7, t),
    );
  }
}

void _handshake(_Scene s) {
  final u = s.u;
  s.ground();
  for (var i = 0; i < 5; i++) {
    final x = 220 + i * 140.0;
    final shake = math.sin(u * 10 + i) * 4;
    s.player(x - 26, 420 + shake, 'home', no: '${i + 4}', front: false, armOut: .5);
    s.player(x + 26, 420 - shake, 'away', no: '${i + 6}', front: true, armOut: .5, face: 'idle');
  }
  s.flush();
}

/// [Sprint 44 B3] The studio: two commentators at their desk, the LED wall with the score, between the moments.
void _studio(_Scene s) {
  final u = s.u;
  final wall = const Rect.fromLTWH(0, 0, frameW, frameH);
  s.c.drawRect(
    wall,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0A1628), Color.lerp(s.l.night, Colors.black, .4)!],
      ).createShader(wall),
  );
  // The LED wall: the crest's gold, the match's clock and score (the d's text).
  final led = const Rect.fromLTWH(250, 50, 500, 220);
  s.c.drawRRect(
    RRect.fromRectAndRadius(led, const Radius.circular(12)),
    Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(s.l.shirt('home'), Colors.black, .55)!,
          const Color(0xFF0B1220),
          Color.lerp(s.l.shirt('away'), Colors.black, .55)!,
        ],
      ).createShader(led),
  );
  for (var y = led.top; y < led.bottom; y += 6) {
    s.c.drawLine(Offset(led.left, y), Offset(led.right, y), Paint()..color = Colors.black.withValues(alpha: .18));
  }
  text(s.c, s.str('score'), led.center - const Offset(0, 14), size: 64, family: 'BarlowCondensed');
  text(s.c, s.str('clock'), led.center + const Offset(0, 52), size: 22, color: s.l.gold, letter: 3);
  // The desk and the two commentators, the one talking moving his hands.
  for (final (x, talk) in [(380.0, (u ~/ 2.2) % 2 == 0), (620.0, (u ~/ 2.2) % 2 == 1)]) {
    drawPlayer(
      s.c,
      x,
      600,
      shirt: x < 500 ? const Color(0xFF263238) : const Color(0xFF3E2723),
      ink: Colors.white,
      shorts: const Color(0xFF263238),
      front: true,
      armOut: talk ? (.3 + .3 * math.sin(u * 8).abs()) : 0,
      face: talk && math.sin(u * 14) > 0 ? 'surprise' : 'idle',
      scale: 1.8,
      shadow: false,
    );
  }
  final desk = const Rect.fromLTWH(200, 430, 600, 132);
  s.c.drawPath(
    Path()
      ..moveTo(desk.left + 40, desk.top)
      ..lineTo(desk.right - 40, desk.top)
      ..lineTo(desk.right, desk.bottom)
      ..lineTo(desk.left, desk.bottom)
      ..close(),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E3550), Color(0xFF0B1A2C)],
      ).createShader(desk),
  );
  s.c.drawLine(
    Offset(desk.left + 40, desk.top),
    Offset(desk.right - 40, desk.top),
    Paint()
      ..color = s.l.gold
      ..strokeWidth = 3,
  );
  text(s.c, 'GAME LEGEND MANAGER', desk.center + const Offset(0, 10), size: 20, color: s.l.gold, letter: 4);
}
