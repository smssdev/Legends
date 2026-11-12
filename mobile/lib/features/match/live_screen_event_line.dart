part of 'live_screen.dart';

/// One line of commentary: the minute, a mark for its kind, and the server's sentence.
class EventLine extends StatelessWidget {
  const EventLine(this.e, {super.key});

  final MatchEvent e;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icon = switch (e.type) {
      'goal' => '⚽',
      'card' => e.color == 'red' ? '🟥' : '🟨',
      'sub' => '🔁',
      'injury' => '🩹',
      'penalty' => '🎯',
      'corner' => '⛳',
      'period' => '⏱',
      _ => '•',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ShapeDecoration(
        color: e.type == 'goal' ? p.gold.withValues(alpha: .16) : p.surface,
        shape: GlmCut.shape(GlmCut.badge, side: BorderSide(color: e.type == 'goal' ? p.gold.withValues(alpha: .5) : p.surfaceRaised)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              e.clock,
              textDirection: TextDirection.ltr,
              style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
            ),
          ),
          Text(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(e.text ?? '', style: TextStyle(fontWeight: e.big ? FontWeight.w800 : FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
