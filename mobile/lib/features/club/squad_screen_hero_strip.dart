part of 'squad_screen.dart';

/// [Sprint 73 D2] The strip that opens and closes the team's hero on a short screen: one line, a whole touch high.
class _HeroStrip extends StatelessWidget {
  const _HeroStrip({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Semantics(
      button: true,
      expanded: open,
      label: l.squadOverview,
      excludeSemantics: true,
      child: Material(
        color: GlmStage.card,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.squadOverview,
                  style: glmText(GlmType.body, color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: context.palette.goldLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pin extends CustomPainter {
  @override
  void paint(Canvas c, Size s) => c.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width / 2, s.height)
      ..close(),
    Paint()..color = GlmArt.skyGlow,
  );

  @override
  bool shouldRepaint(_Pin old) => false;
}

/// A little pitch in perspective, its grass, lines and edge.
class _MiniPitch extends CustomPainter {
  _MiniPitch(this.grass, this.dark);

  final Color grass, dark;

  @override
  void paint(Canvas c, Size s) {
    final top = Path()
      ..moveTo(s.width * .12, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width * .88, s.height * .82)
      ..lineTo(0, s.height * .82)
      ..close();
    c.drawPath(top.shift(Offset(0, s.height * .12)), Paint()..color = GlmArt.earth);
    c.drawPath(top, Paint()..shader = LinearGradient(colors: [Color.lerp(grass, Colors.white, .15)!, dark]).createShader(Offset.zero & s));
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    c.drawPath(top, line);
    c.drawLine(Offset(s.width * .56, 0), Offset(s.width * .44, s.height * .82), line);
    c.drawOval(Rect.fromCenter(center: Offset(s.width * .5, s.height * .41), width: s.width * .16, height: s.height * .4), line);
  }

  @override
  bool shouldRepaint(_MiniPitch old) => false;
}
