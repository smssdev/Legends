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
