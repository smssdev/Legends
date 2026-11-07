import 'package:flutter/material.dart';

import '../../core/sounds.dart';
import '../theme.dart';

/// [Sprint 15 F2] The screens' ground as on the web: a night pitch glow (or warm paper by day) behind everything.
class GlmBackground extends StatelessWidget {
  const GlmBackground({super.key, required this.child, this.wide = false});

  final Widget child;

  /// A screen laid out for the whole width (two columns, a rail); otherwise a single column centred on wide screens,
  /// so a list never stretches across a landscape phone.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = wide ? child : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: child));
    // [Sprint 47] The approved design: by night the web's ink, flat, with an emerald glow from the top as from the
    // floodlights; by day the warm paper as before.
    if (!context.glm.day) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -1.25), radius: 1.2, colors: [Color.lerp(p.bg, p.brand, .22)!, p.bg, p.bg], stops: const [0, .6, 1]),
        ),
        child: body,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(center: const Alignment(0, -1.1), radius: 1.35, colors: [p.surface, p.bg, p.bgDeep], stops: const [0, .55, 1]),
      ),
      child: CustomPaint(painter: _Stripes(Colors.white.withValues(alpha: 0), lines: p.textMuted.withValues(alpha: .06), light: Colors.white.withValues(alpha: 0)), child: body),
    );
  }
}

class _Stripes extends CustomPainter {
  _Stripes(this.color, {required this.lines, required this.light});

  final Color color, lines, light;

  @override
  void paint(Canvas canvas, Size size) {
    // The floodlights.
    for (final c in [Offset(0, 0), Offset(size.width, 0)]) {
      final r = size.shortestSide * .9;
      canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [light, light.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    }
    // The pitch: its outline, the halfway line and circle, both boxes; lying across a wide screen, upright on a tall one.
    final pen = Paint()
      ..color = lines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final wide = size.width >= size.height;
    final m = size.shortestSide * .06;
    final f = Rect.fromLTRB(m, m, size.width - m, size.height - m);
    canvas.drawRect(f, pen);
    if (wide) {
      canvas.drawLine(Offset(f.center.dx, f.top), Offset(f.center.dx, f.bottom), pen);
      for (final left in [true, false]) {
        final x = left ? f.left : f.right, d = left ? 1.0 : -1.0;
        canvas.drawRect(Rect.fromPoints(Offset(x, f.center.dy - f.height * .3), Offset(x + d * f.width * .14, f.center.dy + f.height * .3)), pen);
        canvas.drawRect(Rect.fromPoints(Offset(x, f.center.dy - f.height * .13), Offset(x + d * f.width * .05, f.center.dy + f.height * .13)), pen);
      }
    } else {
      canvas.drawLine(Offset(f.left, f.center.dy), Offset(f.right, f.center.dy), pen);
      for (final top in [true, false]) {
        final y = top ? f.top : f.bottom, d = top ? 1.0 : -1.0;
        canvas.drawRect(Rect.fromPoints(Offset(f.center.dx - f.width * .3, y), Offset(f.center.dx + f.width * .3, y + d * f.height * .14)), pen);
      }
    }
    canvas.drawCircle(f.center, size.shortestSide * .16, pen);
    canvas.drawCircle(f.center, 3, Paint()..color = lines);
    if (color.a == 0) return;
    final paint = Paint()..color = color;
    const w = 46.0;
    for (var x = -size.height; x < size.width; x += w * 2) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w, 0)
        ..lineTo(x + w + size.height * .5, size.height)
        ..lineTo(x + size.height * .5, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_Stripes old) => old.color != color || old.lines != lines || old.light != light;
}

/// A short message at the bottom (the web's toast): an error in red, the rest quiet.
void showGlmToast(BuildContext context, String message, {bool error = false}) {
  final p = context.palette;
  GameSounds.play(error ? Sfx.error : Sfx.confirm);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? p.live : p.surfaceRaised,
      duration: Duration(seconds: error ? 5 : 3),
    ));
}
