import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// [Sprint 46] The game's own icon set, glossy and solid like a game's (our drawings, in code: no image weight). Each is a
/// filled shape lit from its top (a gradient, a white sheen across its upper half), a dark edge and a soft drop shadow,
/// so the menu, the office's tiles and the top bar read at a glance.
enum GameGlyph {
  office, squad, lineup, tactics, training, specialists, transfers, scout, friendlies, quick, quests, predict, table, results,
  camp, stadium, finance, sponsors, medic, contracts, honours, newspaper, spy, groups, alliance, shop, invite, bell, clock, kit, match,
}

class GameIcon extends StatelessWidget {
  const GameIcon(this.glyph, {super.key, this.size = 40});

  final GameGlyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size, child: CustomPaint(painter: _Glyph(glyph)));
}

class _Glyph extends CustomPainter {
  _Glyph(this.g);

  final GameGlyph g;

  @override
  void paint(Canvas canvas, Size s) {
    final c = canvas;
    c.scale(s.width / 100, s.height / 100);
    switch (g) {
      case GameGlyph.office:
        _solid(c, Path()..moveTo(14, 48)..lineTo(50, 16)..lineTo(86, 48)..lineTo(78, 48)..lineTo(78, 86)..lineTo(22, 86)..lineTo(22, 48)..close(), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
        _solid(c, _rr(42, 60, 16, 26, 3), GlmStage.questTop, GlmStage.questBottom);
      case GameGlyph.squad || GameGlyph.kit:
        _shirt(c, const Color(0xFFFFD23F), const Color(0xFF2B7ED3));
      case GameGlyph.lineup:
        _solid(c, _rr(14, 14, 72, 72, 10), const Color(0xFF5BD46A), const Color(0xFF1F8E3A));
        final l = _line(Colors.white, 4);
        c.drawRect(const Rect.fromLTWH(24, 24, 52, 52), l);
        c.drawLine(const Offset(24, 50), const Offset(76, 50), l);
        c.drawCircle(const Offset(50, 50), 9, l);
        c.drawRect(const Rect.fromLTWH(38, 24, 24, 10), l);
        c.drawRect(const Rect.fromLTWH(38, 66, 24, 10), l);
      case GameGlyph.tactics:
        _solid(c, _rr(10, 16, 80, 66, 6), const Color(0xFFB0763A), const Color(0xFF6E431B));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(17, 23, 66, 52), const Radius.circular(3)), Paint()..color = const Color(0xFF235A3C));
        final chalk = _line(Colors.white, 3.5);
        c.drawPath(Path()..moveTo(28, 62)..quadraticBezierTo(44, 34, 64, 40), chalk);
        c.drawPath(Path()..moveTo(58, 34)..lineTo(65, 40)..lineTo(57, 45), chalk);
        for (final p in [const Offset(30, 36), const Offset(68, 62)]) {
          c.drawLine(p - const Offset(5, 5), p + const Offset(5, 5), chalk);
          c.drawLine(p - const Offset(5, -5), p + const Offset(5, -5), chalk);
        }
      case GameGlyph.training:
        _solid(c, Path()..moveTo(50, 10)..lineTo(70, 78)..lineTo(30, 78)..close(), const Color(0xFFFFB13D), const Color(0xFFE2620E));
        c.drawPath(Path()..moveTo(41, 42)..lineTo(59, 42)..lineTo(62, 54)..lineTo(38, 54)..close(), Paint()..color = Colors.white.withValues(alpha: .92));
        _solid(c, _rr(18, 76, 64, 12, 4), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
      case GameGlyph.specialists:
        _solid(c, Path()..moveTo(16, 24)..quadraticBezierTo(50, 12, 84, 24)..lineTo(84, 74)..quadraticBezierTo(50, 62, 16, 74)..close(), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
        c.drawPath(Path()..moveTo(16, 40)..quadraticBezierTo(50, 28, 84, 40)..lineTo(84, 58)..quadraticBezierTo(50, 46, 16, 58)..close(), Paint()..color = GlmStage.questTop);
        _star(c, const Offset(50, 46), 10, const Color(0xFF1D5FC4));
      case GameGlyph.transfers:
        _solid(c, _rr(20, 12, 54, 74, 6), Colors.white, const Color(0xFFCFD8E6));
        final ink = _line(const Color(0xFFB0BCD0), 3);
        for (var y = 26.0; y < 74; y += 10) {
          c.drawLine(Offset(28, y), Offset(60, y), ink);
        }
        _arrow(c, const Offset(70, 54), up: true, color: const Color(0xFF3DCB48), dark: const Color(0xFF1B8A2A));
        _arrow(c, const Offset(56, 60), up: false, color: const Color(0xFFFF5A4E), dark: const Color(0xFFC0281F));
      case GameGlyph.scout:
        for (final x in [32.0, 68.0]) {
          _solid(c, Path()..addOval(Rect.fromCircle(center: Offset(x, 58), radius: 20)), const Color(0xFF5B6E8C), const Color(0xFF222F45));
          c.drawCircle(Offset(x, 58), 11, Paint()..shader = const RadialGradient(colors: [Color(0xFF9FD8FF), Color(0xFF2B7ED3)]).createShader(Rect.fromCircle(center: Offset(x, 58), radius: 11)));
        }
        _solid(c, _rr(42, 40, 16, 16, 4), const Color(0xFF5B6E8C), const Color(0xFF222F45));
      case GameGlyph.friendlies:
        _solid(c, Path()..moveTo(18, 18)..lineTo(82, 18)..lineTo(50, 88)..close(), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
        c.drawPath(Path()..moveTo(30, 28)..lineTo(70, 28)..lineTo(50, 72)..close(), Paint()..color = GlmStage.questTop);
      case GameGlyph.quick:
        _cup(c);
        _shadowText(c, 'VS', const Offset(50, 46), 26);
      case GameGlyph.quests:
        for (final (r, col) in [(36.0, const Color(0xFFE53935)), (26.0, Colors.white), (16.0, const Color(0xFFE53935)), (7.0, Colors.white)]) {
          c.drawCircle(const Offset(54, 46), r, Paint()..color = col);
        }
        c.drawCircle(const Offset(54, 46), 36, _line(const Color(0xFF8E1B18), 2.5));
        for (final (x, y) in [(18.0, 78.0), (30.0, 84.0), (78.0, 80.0)]) {
          _solid(c, Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: 26, height: 14)), GlmStage.questTop, GlmStage.questBottom);
        }
      case GameGlyph.predict:
        _solid(c, _rr(12, 22, 76, 60, 8), const Color(0xFF6B7C96), const Color(0xFF2B3A52));
        for (final x in [22.0, 54.0]) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 40, 24, 34), const Radius.circular(3)), Paint()..color = Colors.white);
          _shadowText(c, '0', Offset(x + 12, 58), 24, color: x < 50 ? const Color(0xFF1B8A2A) : const Color(0xFFC0281F), shadow: false);
        }
        _shadowText(c, '90:00', const Offset(50, 31), 12, shadow: false);
      case GameGlyph.table || GameGlyph.results:
        _solid(c, _rr(16, 20, 68, 66, 8), Colors.white, const Color(0xFFCFD8E6));
        c.drawRRect(RRect.fromRectAndCorners(const Rect.fromLTWH(16, 20, 68, 16), topLeft: const Radius.circular(8), topRight: const Radius.circular(8)), Paint()..color = const Color(0xFF4FA3FF));
        for (final x in [30.0, 50.0, 70.0]) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 18), width: 6, height: 14), const Radius.circular(3)), Paint()..color = const Color(0xFF1D5FC4));
        }
        if (g == GameGlyph.table) {
          c.drawPath(Path()..moveTo(26, 72)..lineTo(40, 58)..lineTo(52, 66)..lineTo(74, 46), _line(const Color(0xFF2FA046), 4.5));
        } else {
          final ink = _line(const Color(0xFFB0BCD0), 3);
          for (var y = 46.0; y < 80; y += 10) {
            c.drawLine(Offset(26, y), Offset(74, y), ink);
          }
        }
      case GameGlyph.camp:
        _solid(c, Path()..moveTo(50, 14)..lineTo(88, 84)..lineTo(12, 84)..close(), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
        c.drawPath(Path()..moveTo(50, 40)..lineTo(64, 84)..lineTo(36, 84)..close(), Paint()..color = const Color(0xFF0F2248));
        c.drawLine(const Offset(50, 14), const Offset(50, 4), _line(const Color(0xFF6E431B), 3));
        c.drawPath(Path()..moveTo(50, 4)..lineTo(64, 8)..lineTo(50, 12)..close(), Paint()..color = GlmStage.questBottom);
      case GameGlyph.stadium:
        _solid(c, Path()..addOval(const Rect.fromLTWH(10, 26, 80, 54)), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
        c.drawOval(const Rect.fromLTWH(24, 36, 52, 34), Paint()..color = const Color(0xFF2FA046));
        c.drawOval(const Rect.fromLTWH(24, 36, 52, 34), _line(Colors.white, 2.5));
        for (final x in [14.0, 86.0]) {
          c.drawLine(Offset(x, 30), Offset(x, 12), _line(const Color(0xFFCFD8E6), 3));
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 12), width: 14, height: 6), const Radius.circular(2)), Paint()..color = Colors.white);
        }
      case GameGlyph.finance:
        _solid(c, Path()..moveTo(12, 38)..lineTo(50, 14)..lineTo(88, 38)..close(), const Color(0xFFCFD8E6), const Color(0xFF7D8CA6));
        for (final x in [22.0, 40.0, 58.0, 76.0]) {
          _solid(c, _rr(x - 4, 40, 9, 34, 2), Colors.white, const Color(0xFFB0BCD0));
        }
        _solid(c, _rr(10, 76, 80, 10, 3), const Color(0xFFCFD8E6), const Color(0xFF7D8CA6));
      case GameGlyph.sponsors:
        _solid(c, _rr(12, 16, 76, 50, 6), const Color(0xFFFFD23F), const Color(0xFFC08A0C));
        c.drawRect(const Rect.fromLTWH(18, 22, 64, 38), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9FD8FF), Color(0xFF2B7ED3)]).createShader(const Rect.fromLTWH(18, 22, 64, 38)));
        c.drawLine(const Offset(50, 66), const Offset(50, 88), _line(const Color(0xFF5B6E8C), 5));
        c.drawLine(const Offset(36, 88), const Offset(64, 88), _line(const Color(0xFF5B6E8C), 5));
      case GameGlyph.medic:
        _solid(c, _rr(14, 26, 72, 56, 10), const Color(0xFFFF5A4E), const Color(0xFFC0281F));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(36, 16, 28, 14), const Radius.circular(4)), _line(const Color(0xFFC0281F), 5));
        c.drawRect(const Rect.fromLTWH(44, 38, 12, 34), Paint()..color = Colors.white);
        c.drawRect(const Rect.fromLTWH(33, 49, 34, 12), Paint()..color = Colors.white);
      case GameGlyph.contracts:
        _solid(c, _rr(18, 12, 56, 76, 6), Colors.white, const Color(0xFFCFD8E6));
        final ink = _line(const Color(0xFFB0BCD0), 3);
        for (var y = 26.0; y < 60; y += 10) {
          c.drawLine(Offset(26, y), Offset(66, y), ink);
        }
        c.drawPath(Path()..moveTo(28, 74)..quadraticBezierTo(38, 62, 46, 74)..quadraticBezierTo(54, 84, 62, 70), _line(const Color(0xFF1D5FC4), 3.5));
        c.save();
        c.translate(76, 56);
        c.rotate(.6);
        _solid(c, _rr(-5, -30, 10, 44, 3), GlmStage.questTop, GlmStage.questBottom);
        c.restore();
      case GameGlyph.honours:
        _cup(c);
        _star(c, const Offset(50, 42), 12, Colors.white);
      case GameGlyph.newspaper:
        _solid(c, _rr(12, 20, 76, 62, 6), Colors.white, const Color(0xFFCFD8E6));
        c.drawRect(const Rect.fromLTWH(20, 28, 60, 12), Paint()..color = const Color(0xFF0F2248));
        c.drawRect(const Rect.fromLTWH(20, 46, 26, 26), Paint()..color = const Color(0xFF4FA3FF));
        final ink = _line(const Color(0xFFB0BCD0), 3);
        for (var y = 48.0; y < 74; y += 8) {
          c.drawLine(Offset(52, y), Offset(80, y), ink);
        }
      case GameGlyph.spy:
        _solid(c, Path()..moveTo(8, 50)..quadraticBezierTo(50, 10, 92, 50)..quadraticBezierTo(50, 90, 8, 50)..close(), Colors.white, const Color(0xFFCFD8E6));
        c.drawCircle(const Offset(50, 50), 18, Paint()..shader = const RadialGradient(colors: [Color(0xFF4FE0B5), Color(0xFF0A7559)]).createShader(Rect.fromCircle(center: const Offset(50, 50), radius: 18)));
        c.drawCircle(const Offset(50, 50), 8, Paint()..color = const Color(0xFF0F2248));
        c.drawCircle(const Offset(45, 45), 4, Paint()..color = Colors.white);
      case GameGlyph.groups:
        _solid(c, Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 16, 56, 40), const Radius.circular(14)))..moveTo(20, 54)..lineTo(16, 68)..lineTo(32, 56), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
        _solid(c, Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(36, 40, 54, 38), const Radius.circular(14)))..moveTo(78, 76)..lineTo(84, 88)..lineTo(68, 78), Colors.white, const Color(0xFFCFD8E6));
        for (final x in [52.0, 63.0, 74.0]) {
          c.drawCircle(Offset(x, 59), 4, Paint()..color = const Color(0xFF1D5FC4));
        }
      case GameGlyph.alliance:
        for (final (x, top, bottom) in [(36.0, const Color(0xFF4FA3FF), const Color(0xFF1D5FC4)), (64.0, const Color(0xFFFF5A4E), const Color(0xFFC0281F))]) {
          _solid(c, Path()..moveTo(x, 14)..quadraticBezierTo(x + 20, 20, x + 24, 18)..quadraticBezierTo(x + 24, 64, x, 86)..quadraticBezierTo(x - 24, 64, x - 24, 18)..quadraticBezierTo(x - 20, 20, x, 14)..close(), top, bottom);
        }
      case GameGlyph.shop:
        _solid(c, Path()..moveTo(50, 10)..lineTo(84, 30)..lineTo(84, 66)..lineTo(50, 90)..lineTo(16, 66)..lineTo(16, 30)..close(), GlmStage.questTop, GlmStage.questBottom);
        _solid(c, Path()..moveTo(50, 26)..lineTo(68, 38)..lineTo(50, 74)..lineTo(32, 38)..close(), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
      case GameGlyph.invite:
        for (final (x, col) in [(36.0, const Color(0xFF4FA3FF)), (62.0, const Color(0xFF2FA046))]) {
          _solid(c, Path()..addOval(Rect.fromCircle(center: Offset(x, 34), radius: 14)), const Color(0xFFF2C6A0), const Color(0xFFB5794F));
          _solid(c, Path()..addRRect(RRect.fromRectAndCorners(Rect.fromLTWH(x - 20, 50, 40, 34), topLeft: const Radius.circular(18), topRight: const Radius.circular(18))), Color.lerp(col, Colors.white, .2)!, col);
        }
      case GameGlyph.bell:
        _solid(c, Path()..moveTo(50, 14)..quadraticBezierTo(76, 18, 76, 46)..lineTo(84, 72)..lineTo(16, 72)..lineTo(24, 46)..quadraticBezierTo(24, 18, 50, 14)..close(), GlmStage.questTop, GlmStage.questBottom);
        c.drawCircle(const Offset(50, 80), 8, Paint()..color = GlmStage.questBottom);
      case GameGlyph.clock:
        _solid(c, Path()..addOval(Rect.fromCircle(center: const Offset(50, 54), radius: 34)), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
        c.drawCircle(const Offset(50, 54), 26, Paint()..color = Colors.white);
        c.drawLine(const Offset(50, 54), const Offset(50, 36), _line(const Color(0xFF0F2248), 4));
        c.drawLine(const Offset(50, 54), const Offset(64, 60), _line(const Color(0xFF0F2248), 4));
        _solid(c, _rr(42, 10, 16, 10, 3), const Color(0xFF4FA3FF), const Color(0xFF1D5FC4));
      case GameGlyph.match:
        _solid(c, Path()..addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 38)), Colors.white, const Color(0xFFCFD8E6));
        final p = Paint()..color = const Color(0xFF1C1C1C);
        c.drawPath(_poly(const Offset(50, 50), 12, 5, -math.pi / 2), p);
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 5;
          c.drawPath(_poly(Offset(50 + math.cos(a) * 30, 50 + math.sin(a) * 30), 9, 5, a + math.pi / 2), p);
        }
    }
  }

  @override
  bool shouldRepaint(_Glyph old) => old.g != g;
}

Path _rr(double x, double y, double w, double h, double r) => Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)));

Paint _line(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Path _poly(Offset c, double r, int n, double start) {
  final p = Path();
  for (var i = 0; i < n; i++) {
    final a = start + i * 2 * math.pi / n;
    final pt = c + Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// A glossy solid: a drop shadow, a fill lit from the top, a sheen over its upper half, a dark edge.
void _solid(Canvas c, Path p, Color top, Color bottom) {
  final b = p.getBounds();
  c.drawPath(p.shift(const Offset(0, 4)), Paint()..color = Colors.black.withValues(alpha: .28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  c.drawPath(p, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(top, Colors.white, .15)!, top, bottom], stops: const [0, .45, 1]).createShader(b));
  c.save();
  c.clipPath(p);
  c.drawOval(Rect.fromLTWH(b.left - b.width * .1, b.top - b.height * .55, b.width * 1.2, b.height), Paint()..color = Colors.white.withValues(alpha: .22));
  c.restore();
  c.drawPath(p, _line(Color.lerp(bottom, Colors.black, .35)!, 2.2));
}

void _shirt(Canvas c, Color body, Color trim) {
  final p = Path()
    ..moveTo(36, 12)
    ..quadraticBezierTo(50, 24, 64, 12)
    ..lineTo(88, 24)
    ..lineTo(96, 46)
    ..lineTo(78, 52)
    ..lineTo(76, 90)
    ..lineTo(24, 90)
    ..lineTo(22, 52)
    ..lineTo(4, 46)
    ..lineTo(12, 24)
    ..close();
  _solid(c, p, body, Color.lerp(body, Colors.black, .25)!);
  c.save();
  c.clipPath(p);
  c.drawRect(const Rect.fromLTWH(42, 12, 16, 80), Paint()..color = trim);
  c.restore();
  c.drawPath(Path()..moveTo(36, 12)..quadraticBezierTo(50, 24, 64, 12), _line(trim, 5));
}

void _cup(Canvas c) {
  c.drawArc(const Rect.fromLTWH(10, 22, 26, 30), math.pi / 2, math.pi, false, _line(GlmStage.questBottom, 6));
  c.drawArc(const Rect.fromLTWH(64, 22, 26, 30), -math.pi / 2, math.pi, false, _line(GlmStage.questBottom, 6));
  _solid(c, Path()..moveTo(24, 14)..lineTo(76, 14)..quadraticBezierTo(76, 62, 50, 66)..quadraticBezierTo(24, 62, 24, 14)..close(), GlmStage.questTop, GlmStage.questBottom);
  _solid(c, _rr(42, 64, 16, 12, 2), GlmStage.questTop, GlmStage.questBottom);
  _solid(c, _rr(28, 76, 44, 12, 3), const Color(0xFF6E431B), const Color(0xFF3E2410));
}

void _arrow(Canvas c, Offset at, {required bool up, required Color color, required Color dark}) {
  final d = up ? -1.0 : 1.0;
  final p = Path()
    ..moveTo(at.dx, at.dy + d * 30)
    ..lineTo(at.dx + 14, at.dy + d * 14)
    ..lineTo(at.dx + 6, at.dy + d * 14)
    ..lineTo(at.dx + 6, at.dy - d * 4)
    ..lineTo(at.dx - 6, at.dy - d * 4)
    ..lineTo(at.dx - 6, at.dy + d * 14)
    ..lineTo(at.dx - 14, at.dy + d * 14)
    ..close();
  _solid(c, p, color, dark);
}

void _star(Canvas c, Offset at, double r, Color color) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5, rr = i.isEven ? r : r * .45;
    final pt = at + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  c.drawPath(p..close(), Paint()..color = color);
}

void _shadowText(Canvas c, String t, Offset at, double size, {Color color = Colors.white, bool shadow = true}) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: TextStyle(fontFamily: 'BarlowCondensed', fontWeight: FontWeight.w800, fontSize: size, color: color, height: 1,
        shadows: shadow ? const [Shadow(color: Color(0xAA000000), offset: Offset(0, 2), blurRadius: 2)] : null)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
}
