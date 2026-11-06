import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.g.dart';

/// [2026-11-06, stage 3] The game's pictures drawn in code, sharp at any size and weighing nothing: a football shirt
/// in two colours with a number on its chest (the lineup's players), and a shield with a club's code (a crest still
/// loading, or one the API has none for).

/// A football shirt: the body in [color], collar and cuffs in [trim], [label] on the chest, and a gold ring when picked.
class KitShirt extends StatelessWidget {
  const KitShirt({super.key, required this.color, required this.trim, this.label, this.size = 44, this.picked = false});

  final Color color, trim;
  final String? label;
  final double size;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final fg = color.computeLuminance() > .45 ? context.palette.bgDeep : Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Shirt(color: color, trim: trim, ring: picked ? context.palette.gold : null),
        child: label == null
            ? null
            : Padding(
                padding: EdgeInsets.only(top: size * .18),
                child: Center(
                  child: Text(label!, textDirection: TextDirection.ltr,
                      style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: size * .34, color: fg, height: 1,
                          shadows: [Shadow(color: Colors.black.withValues(alpha: .25), blurRadius: 2, offset: const Offset(0, 1))])),
                ),
              ),
      ),
    );
  }
}

class _Shirt extends CustomPainter {
  _Shirt({required this.color, required this.trim, this.ring});

  final Color color, trim;
  final Color? ring;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // The silhouette: shoulders, short sleeves, a slightly tapered body.
    final shirt = Path()
      ..moveTo(w * .36, h * .08)
      ..quadraticBezierTo(w * .5, h * .20, w * .64, h * .08)
      ..lineTo(w * .86, h * .17)
      ..lineTo(w * .99, h * .42)
      ..lineTo(w * .83, h * .50)
      ..lineTo(w * .78, h * .40)
      ..lineTo(w * .79, h * .94)
      ..quadraticBezierTo(w * .5, h * .99, w * .21, h * .94)
      ..lineTo(w * .22, h * .40)
      ..lineTo(w * .17, h * .50)
      ..lineTo(w * .01, h * .42)
      ..lineTo(w * .14, h * .17)
      ..close();
    canvas.drawShadow(shirt, Colors.black, 3, true);
    final r = Offset.zero & s;
    canvas.drawPath(shirt, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(color, Colors.white, .22)!, color, Color.lerp(color, Colors.black, .18)!], stops: const [0, .45, 1]).createShader(r));
    canvas.save();
    canvas.clipPath(shirt);
    // The cuffs and the side panels in the trim colour.
    final t = Paint()..color = trim;
    canvas.drawPath(Path()..moveTo(w * .99, h * .42)..lineTo(w * .83, h * .50)..lineTo(w * .80, h * .44)..lineTo(w * .96, h * .36)..close(), t);
    canvas.drawPath(Path()..moveTo(w * .01, h * .42)..lineTo(w * .17, h * .50)..lineTo(w * .20, h * .44)..lineTo(w * .04, h * .36)..close(), t);
    // A soft light across one shoulder.
    canvas.drawPath(shirt, Paint()..shader = RadialGradient(center: const Alignment(-.5, -.8), radius: .9, colors: [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: 0)]).createShader(r));
    canvas.restore();
    // The collar.
    canvas.drawPath(
      Path()
        ..moveTo(w * .36, h * .08)
        ..quadraticBezierTo(w * .5, h * .20, w * .64, h * .08),
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .06
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(shirt, Paint()
      ..color = ring ?? Colors.black.withValues(alpha: .25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring == null ? 1 : w * .07
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_Shirt old) => old.color != color || old.trim != trim || old.ring != ring;
}

/// A club's shield: a heater shield lit from the top, a gold rim, and the club's code across it.
class CrestShield extends StatelessWidget {
  const CrestShield({super.key, required this.code, this.color, this.size = 44});

  final String code;

  /// The club's colour, when known; otherwise the game's own blue.
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? GlmLine.def.bg;
    final fg = c.computeLuminance() > .5 ? context.palette.bgDeep : Colors.white;
    final text = code.characters.take(3).toString().toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Shield(color: c, rim: p.gold),
        child: Padding(
          padding: EdgeInsets.only(bottom: size * .1),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size * .18),
                child: Text(text, textDirection: TextDirection.ltr,
                    style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: size * .30, color: fg, letterSpacing: .5, height: 1)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shield extends CustomPainter {
  _Shield({required this.color, required this.rim});

  final Color color, rim;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    Path shield(double inset) => Path()
      ..moveTo(w * .5, h * .04 + inset)
      ..quadraticBezierTo(w * .72, h * .14 + inset, w * .90 - inset, h * .13 + inset)
      ..quadraticBezierTo(w * .92 - inset, h * .62, w * .5, h * .96 - inset)
      ..quadraticBezierTo(w * .08 + inset, h * .62, w * .10 + inset, h * .13 + inset)
      ..quadraticBezierTo(w * .28, h * .14 + inset, w * .5, h * .04 + inset)
      ..close();
    final outer = shield(0), inner = shield(w * .07);
    final r = Offset.zero & s;
    canvas.drawShadow(outer, Colors.black, 3, true);
    canvas.drawPath(outer, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(rim, Colors.white, .35)!, rim, Color.lerp(rim, Colors.black, .35)!]).createShader(r));
    canvas.drawPath(inner, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(color, Colors.white, .20)!, color, Color.lerp(color, Colors.black, .30)!]).createShader(r));
    // A band of light across the upper half.
    canvas.save();
    canvas.clipPath(inner);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * .42), Paint()..color = Colors.white.withValues(alpha: .10));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Shield old) => old.color != color || old.rim != rim;
}
