import '../../../ui/art_palette.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art.dart';

part 'clips_flashes.dart';
part 'clips_corner.dart';
part 'clips_coach_react.dart';

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
      shorts: GlmArt.black,
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
        s.actors.add((999, () => drawBurst(s.c, const Offset(470, 300), 'BLOCK!', seg(u, keyT, keyT + .9), color: GlmArt.burst)));
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
