part of 'clips.dart';

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
