import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.g.dart';

/// [Sprint 47] The game's crest as drawn in the approved design (the splash, the sign-in, the face-off): a gold
/// shield, the emerald inside, the gold crown and its band, GLM in Barlow Condensed and a gold dot under it. Painted
/// by code, so it is sharp at every size.
class LegendCrest extends StatelessWidget {
  const LegendCrest({super.key, this.size = 150, this.letters = true});

  /// Its width; the height follows (172/150).
  final double size;
  final bool letters;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Game Legend Manager',
    image: true,
    child: CustomPaint(
      size: Size(size, size * 172 / 150),
      painter: _CrestPainter(context.palette, letters: letters),
    ),
  );
}

class _CrestPainter extends CustomPainter {
  _CrestPainter(this.p, {required this.letters});

  final GlmPalette p;
  final bool letters;

  Path _shield(double inset) {
    // The outer shield on a 150 × 172 board; the inner one [inset] inside it.
    final i = inset;
    return Path()
      ..moveTo(75, 6 + i)
      ..lineTo(138 - i, 28 + i * .6)
      ..lineTo(138 - i, 82)
      ..cubicTo(138 - i, 122 - i * .2, 110 - i * .5, 150 - i * .6, 75, 166 - i * 1.2)
      ..cubicTo(40 + i * .5, 150 - i * .6, 12 + i, 122 - i * .2, 12 + i, 82)
      ..lineTo(12 + i, 28 + i * .6)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 150, size.height / 172);
    final gold = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [p.goldLight, p.gold, p.goldDark],
        stops: const [0, .55, 1],
      ).createShader(const Rect.fromLTWH(0, 0, 150, 172));
    final emerald = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [p.brand, p.brandDark],
      ).createShader(const Rect.fromLTWH(0, 0, 150, 172));
    canvas.drawPath(_shield(0), gold);
    canvas.drawPath(_shield(10), emerald);
    // The crown and its band.
    canvas.drawPath(
      Path()
        ..moveTo(48, 50)
        ..lineTo(58, 64)
        ..lineTo(75, 44)
        ..lineTo(92, 64)
        ..lineTo(102, 50)
        ..lineTo(98, 78)
        ..lineTo(52, 78)
        ..close(),
      gold,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52, 82, 46, 6), const Radius.circular(2)), gold);
    if (letters) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'GLM',
          style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: 3, color: glmNight.text),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(75 - tp.width / 2 + 1.5, 96));
      canvas.drawCircle(const Offset(75, 141), 3, Paint()..color = p.gold);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CrestPainter old) => old.p != p || old.letters != letters;
}
