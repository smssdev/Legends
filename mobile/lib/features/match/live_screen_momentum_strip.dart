part of 'live_screen.dart';

/// The score bug: home on the right in Arabic (tokens.json match.homeSide), the minute or «نهاية المباراة» below.
/// The score bar, as on a TV broadcast: each side in its kit's colour (the change kit on a clash), the score between them
/// on a dark plate, and the minute (red while it plays) or «full time» under it. Home on the right in Arabic.
/// [Sprint 50 M15] The momentum wave under the pitch: each minute's danger drawn as a wave (the home side above in its
/// kit's colour, the away side below in its), and the share of the last minutes for the side on top.
class _MomentumStrip extends StatelessWidget {
  const _MomentumStrip({required this.wave, required this.homePct, required this.view});

  final List<int> wave;
  final int? homePct;
  final MatchView view;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final pct = homePct ?? 50;
    final lead = pct >= 50 ? view.home : view.away;
    return Semantics(
      label: '${l.momentum}: ${l.momentumShare(lead.name, pct >= 50 ? pct : 100 - pct)}',
      excludeSemantics: true,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: p.bgDeep.withValues(alpha: .7), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Text(l.momentum, style: TextStyle(color: p.textMuted, fontSize: 11)),
            const SizedBox(width: 8),
            Expanded(
              child: CustomPaint(painter: _Wave(wave, p.brandLight, p.warning), size: Size.infinite),
            ),
            const SizedBox(width: 8),
            Text(
              l.momentumShare(lead.code, pct >= 50 ? pct : 100 - pct),
              style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: pct >= 50 ? p.brandLight : p.warning),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wave extends CustomPainter {
  _Wave(this.wave, this.home, this.away);

  final List<int> wave;
  final Color home, away;

  @override
  void paint(Canvas c, Size s) {
    if (wave.isEmpty) return;
    final mid = s.height / 2;
    final step = s.width / (wave.length > 1 ? wave.length - 1 : 1);
    Path side(bool up) {
      final path = Path()..moveTo(0, mid);
      var before = mid;
      for (final (i, v) in wave.indexed) {
        final h = (up ? v.clamp(0, 2) : -v.clamp(-2, 0)) / 2 * (mid - 2);
        final x = i * step, y = up ? mid - h : mid + h;
        if (i == 0) {
          path.lineTo(x, y);
        } else {
          path.cubicTo(x - step / 2, before, x - step / 2, y, x, y);
        }
        before = y;
      }
      return path
        ..lineTo(s.width, mid)
        ..close();
    }

    c.drawPath(side(true), Paint()..color = home.withValues(alpha: .7));
    c.drawPath(side(false), Paint()..color = away.withValues(alpha: .7));
    c.drawLine(
      Offset(0, mid),
      Offset(s.width, mid),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_Wave o) => true;
}

class _ScoreBug extends StatelessWidget {
  const _ScoreBug({required this.view, required this.score, this.minute, required this.finished});

  final MatchView view;
  final (int, int) score;
  final String? minute;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final kits = matchKits(view);
    Widget side(MatchClub c, String key) {
      final (shirt, ink) = kits[key]!;
      final mine = view.you == key;
      return Expanded(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(shirt, Colors.white, .12)!, shirt],
            ),
            shape: GlmCut.shape(GlmCut.badge + 4, side: mine ? BorderSide(color: p.gold, width: 2) : BorderSide.none),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  c.code,
                  style: TextStyle(
                    fontFamily: GlmFonts.numbers,
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    height: 1,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: ink.withValues(alpha: .85), fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          side(view.home, 'home'),
          const SizedBox(width: 6),
          Container(
            width: 108,
            height: 64,
            decoration: ShapeDecoration(
              color: p.bgDeep,
              shape: GlmCut.shape(GlmCut.badge + 2, side: BorderSide(color: Colors.white.withValues(alpha: .08))),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${score.$1} - ${score.$2}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 32, fontWeight: FontWeight.w800, color: p.text, height: 1),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: ShapeDecoration(color: finished ? p.surfaceRaised : p.danger, shape: GlmCut.shape(GlmCut.chip + 2)),
                    child: Text(
                      finished ? l.fullTime : (minute ?? l.notStarted),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: finished ? p.text : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        fontFamilyFallback: const [GlmFonts.body],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          side(view.away, 'away'),
        ],
      ),
    );
  }
}
