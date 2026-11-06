import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../ui/theme.dart';
import 'frames.dart';
import 'match_data.dart';

/// [Sprint 17 F3] The light pitch for any phone: a `CustomPainter` that draws the server's Keyframes with the same
/// curve as the web and Unity (frames.dart). Each minute plays from its start on the server's clock (`at`), so two
/// screens show the same moment. No game logic: the positions all come from the server.
class LivePitch extends StatefulWidget {
  const LivePitch({super.key, required this.ticks, required this.tickMs, required this.serverOffset, required this.kits, required this.numbers});

  /// The latest minutes with their Keyframes, oldest first.
  final List<LiveTick> ticks;
  final int tickMs;

  /// Server clock minus this phone's clock (ms).
  final int serverOffset;

  /// Each side's shirt and number colours.
  final Map<String, (Color, Color)> kits;

  /// Each player's id → his side and shirt number.
  final Map<String, (String, int)> numbers;

  @override
  State<LivePitch> createState() => _LivePitchState();
}

class _LivePitchState extends State<LivePitch> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}))..start();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  RenderFrame? _frame() {
    final now = DateTime.now().millisecondsSinceEpoch + widget.serverOffset;
    LiveTick? cur;
    for (final t in widget.ticks) {
      if (t.frames.isEmpty) continue;
      if (t.at == null || t.at! <= now) cur = t;
    }
    cur ??= widget.ticks.where((t) => t.frames.isNotEmpty).firstOrNull;
    if (cur == null) return null;
    final u = cur.at == null ? 1.0 : (now - cur.at!) / widget.tickMs;
    return sample(cur.frames, u);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AspectRatio(
      aspectRatio: 105 / 68,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(painter: _PitchPainter(_frame(), widget.kits, widget.numbers, p.pitch, p.pitchDark)),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  _PitchPainter(this.frame, this.kits, this.numbers, this.grass, this.stripe);

  final RenderFrame? frame;
  final Map<String, (Color, Color)> kits;
  final Map<String, (String, int)> numbers;
  final Color grass, stripe;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 1050, sy = size.height / 680;
    canvas.drawRect(Offset.zero & size, Paint()..color = grass);
    final band = Paint()..color = stripe.withValues(alpha: .35);
    for (var i = 0; i < 10; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * size.width / 10, 0, size.width / 10, size.height), band);
    }
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inset = 4.0;
    canvas.drawRect(Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset), line);
    canvas.drawLine(Offset(size.width / 2, inset), Offset(size.width / 2, size.height - inset), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 91.5 * sx, line);
    for (final left in [true, false]) {
      final x0 = left ? inset : size.width - inset, d = left ? 1 : -1;
      canvas.drawRect(Rect.fromPoints(Offset(x0, (340 - 201.6) * sy), Offset(x0 + d * 165 * sx, (340 + 201.6) * sy)), line);
      canvas.drawRect(Rect.fromPoints(Offset(x0, (340 - 91.6) * sy), Offset(x0 + d * 55 * sx, (340 + 91.6) * sy)), line);
    }
    final f = frame;
    if (f == null) return;
    final r = (size.width / 52).clamp(6.0, 13.0);
    for (final e in f.players.entries) {
      final who = numbers[e.key];
      if (who == null) continue;
      final (shirt, ink) = kits[who.$1] ?? (Colors.white, Colors.black);
      final c = Offset(e.value.$1 * sx, e.value.$2 * sy);
      canvas.drawCircle(c.translate(0, 1.5), r, Paint()..color = Colors.black.withValues(alpha: .25));
      canvas.drawCircle(c, r, Paint()..color = shirt);
      canvas.drawCircle(c, r, Paint()
        ..color = ink.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
      final tp = TextPainter(
        text: TextSpan(text: '${who.$2}', style: TextStyle(color: ink, fontSize: r * 1.05, fontWeight: FontWeight.w800, fontFamily: GlmFonts.numbers)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
    for (final o in f.officials ?? const <Point2>[]) {
      canvas.drawCircle(Offset(o.$1 * sx, o.$2 * sy), r * .6, Paint()..color = const Color(0xFF111111));
    }
    final (bx, by, bz) = f.ball;
    final lift = bz * sy * .6;
    canvas.drawCircle(Offset(bx * sx, by * sy), r * .45, Paint()..color = Colors.black.withValues(alpha: .3));
    canvas.drawCircle(Offset(bx * sx, by * sy - lift), r * .5 + bz / 40, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PitchPainter old) => true;
}

/// A club colour from the server ('#C8102E'); white when there is none.
Color hexColor(String? hex, [Color fallback = Colors.white]) {
  final h = hex?.replaceFirst('#', '');
  if (h == null || h.length != 6) return fallback;
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

/// Black or white numbers, whichever reads on the shirt.
Color inkOn(Color shirt) => shirt.computeLuminance() > .5 ? const Color(0xFF111111) : Colors.white;
