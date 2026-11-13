import 'package:flutter/material.dart';

import '../../ui/widgets/cut.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/pitch_name.dart';
import 'squad_screen.dart' show lineColor;
import 'team_data.dart';

// [Sprint 60 F4] One pitch for the lineup and the tactics, in the same place on both (the approved drafts, Lineup.html
// and Tactics.html: «the same pitch in the same place, so going from one to the other does not move the eye»): flat,
// upright at the screen's height, my goal at the foot, each of the eleven a disc with his rating and his name under it.

/// The pitch's grass and markings around [child] (the places on it).
class FlatPitch extends StatelessWidget {
  const FlatPitch({super.key, required this.child, this.horizontal = false});

  final Widget child;

  /// Lying across a narrow screen's width (the lineup held upright).
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: ShapeDecoration(
        shape: GlmCut.shape(GlmCut.card + 4, side: BorderSide(color: Colors.white.withValues(alpha: .12))),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.pitch, p.pitchDark]),
        shadows: [BoxShadow(color: p.shade.withValues(alpha: .45), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -10)],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: PitchLines(Colors.white.withValues(alpha: .35), horizontal: horizontal)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Where a place of the book (x from my goal forward 0..740, y across 0..680) falls on an upright pitch [size], for a
/// token of [token] (its top-left corner); across from the reading start.
Offset placeOnPitch(Slot s, Size size, Size token, {bool rtl = false, bool horizontal = false}) {
  final fwd = (s.x / 740).clamp(0.0, 1.0), across = (s.y / 680).clamp(0.0, 1.0);
  return horizontal
      ? Offset((rtl ? 1 - fwd : fwd) * (size.width - token.width), across * (size.height - token.height))
      : Offset(across * (size.width - token.width), (1 - fwd) * (size.height - token.height));
}

/// A player's place: a disc with his rating (gold when picked or lit), his name under it.
class PitchDisc extends StatelessWidget {
  const PitchDisc({super.key, required this.player, required this.line, this.lit = false});

  final Player player;
  final String line;
  final bool lit;

  static const size = Size(56, 48);

  @override
  Widget build(BuildContext context) {
    final c = lineColor(line);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit ? context.palette.gold : c.bg,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text(
            '${player.overall}',
            style: context.type
                .numbers(context.type.caption)
                .copyWith(color: lit ? context.palette.onGold : c.fg, fontWeight: FontWeight.w800, height: 1),
          ),
        ),
        const SizedBox(height: 1),
        PitchName(player.name.split(' ').last, width: size.width),
      ],
    );
  }
}

/// The eleven at their places, to look at (the tactics): no taps, no dragging.
class ElevenOnPitch extends StatelessWidget {
  const ElevenOnPitch({super.key, required this.team});

  final TeamData team;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final slots = team.lineup.slots, starters = team.lineup.starters;
    return FlatPitch(
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            for (var i = 0; i < slots.length && i < starters.length; i++)
              if (team.byId(starters[i]) case final pl?)
                Positioned.fromRect(
                  rect: placeOnPitch(slots[i], box.biggest, PitchDisc.size, rtl: rtl) & PitchDisc.size,
                  child: PitchDisc(player: pl, line: slots[i].line),
                ),
          ],
        ),
      ),
    );
  }
}

/// The mowing stripes and the markings, drawn upright (turned a quarter for a pitch lying across).
class PitchLines extends CustomPainter {
  PitchLines(this.color, {this.horizontal = false});

  final Color color;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    if (horizontal) {
      canvas.translate(size.width, 0);
      canvas.rotate(1.5707963267948966);
    }
    final s = horizontal ? Size(size.height, size.width) : size;
    final stripe = Paint()..color = Colors.black.withValues(alpha: .07);
    for (var i = 0; i < 10; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, s.height * i / 10, s.width, s.height / 10), stripe);
    }
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6, 6, s.width - 12, s.height - 12), const Radius.circular(12)), pen);
    canvas.drawLine(Offset(6, s.height / 2), Offset(s.width - 6, s.height / 2), pen);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * .14, pen);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), 3, Paint()..color = color);
    for (final top in [true, false]) {
      final y = top ? 6.0 : s.height - 6;
      final d = top ? 1 : -1;
      canvas.drawRect(Rect.fromPoints(Offset(s.width * .22, y), Offset(s.width * .78, y + d * s.height * .15)), pen);
      canvas.drawRect(Rect.fromPoints(Offset(s.width * .38, y), Offset(s.width * .62, y + d * s.height * .06)), pen);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(s.width / 2, y + d * s.height * .15), radius: s.width * .09),
        top ? 0 : 3.141592653589793,
        3.141592653589793,
        false,
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(PitchLines old) => old.color != color || old.horizontal != horizontal;
}
