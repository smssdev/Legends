part of 'squad_screen.dart';

class PlayerRow extends StatelessWidget {
  const PlayerRow(this.p, {super.key, this.onTap, this.selected = false, this.trailing});

  final Player p;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = context.palette;
    // [2026-11-06] A player as a game row: rating badge, position chip, the name, age and role, fitness as a bar.
    final starter = p.role == 'starter';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? c.gold.withValues(alpha: .16) : (starter ? Color.lerp(c.surface, c.pitchDark, .18) : c.surface),
        shape: GlmCut.shape(
          GlmCut.badge + 4,
          side: BorderSide(color: selected ? c.gold : Colors.white.withValues(alpha: context.glm.day ? 0 : .07)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: GlmCut.shape(GlmCut.badge + 4),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  RatingBadge(p.overall, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PositionChip(p.position, p.line),
                            const SizedBox(width: 8),
                            // Player names stay in English in every language (decision 2026-11-01).
                            Flexible(
                              child: Text(
                                p.name,
                                // [Sprint 60 F8] A long name takes a second line in a narrow column, never «…».
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: glmText(GlmType.body, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                !p.available
                                    ? (p.injured > 0 ? '🩹 ${l.injuredFor(p.injured)}' : '🟥 ${l.suspendedFor(p.suspended)}')
                                    : '${l.age(p.age)} · ${starter
                                          ? l.starter
                                          : p.role == 'bench'
                                          ? l.bench
                                          : l.reserve}',
                                maxLines: 2,
                                style: glmText(
                                  GlmType.caption,
                                  color: p.available ? (starter ? context.glm.successText : c.textMuted) : context.glm.liveText,
                                  fontWeight: starter ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${p.fitness}%',
                              style: glmText(GlmType.caption, fontFamily: GlmFonts.numbers, color: c.textMuted),
                            ),
                            const SizedBox(width: 6),
                            LevelBar(p.fitness / 100, color: fitnessColor(p.fitness)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A player's card: his numbers and each attribute as a bar. [Sprint 60 F4] One card, as the site's PlayerCard: beside
/// the squad's table as a panel ([PlayerCardPanel]), in a sheet where there is no table to keep in view.
Future<void> showPlayerCard(BuildContext context, Player p) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  backgroundColor: context.palette.panel,
  builder: (context) => SafeArea(
    child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: PlayerCardBody(p)),
  ),
);

/// [Sprint 60 F4] The card beside the squad's table (the approved draft's side panel): the table stays in view, and a
/// tap on another row puts that player here.
class PlayerCardPanel extends StatelessWidget {
  const PlayerCardPanel({super.key, required this.player, required this.close});

  final Player player;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.panel,
    child: SafeArea(
      left: false,
      right: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(tooltip: L.of(context).close, icon: const Icon(Icons.close_rounded), onPressed: close),
          ),
          Expanded(
            child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: PlayerCardBody(player)),
          ),
        ],
      ),
    ),
  );
}

/// The card's content: his name, position, age and nationality, his four numbers, and each attribute as a bar.
class PlayerCardBody extends StatelessWidget {
  const PlayerCardBody(this.p, {super.key});

  final Player p;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(p.name, textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: context.text.headlineSmall),
        const SizedBox(height: 4),
        Text(
          [p.position, l.age(p.age), if (p.nationality != null) p.nationality!].join(' · '),
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textMuted),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final (v, label) in [
              ('${p.overall}', l.ratingWord),
              ('${p.potential}', l.potentialWord),
              ('${p.fitness}%', l.fitness),
              (money(context, p.value), l.value),
            ])
              Expanded(
                child: FittedBox(fit: BoxFit.scaleDown, child: _big(context, v, label)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l.attributes, style: context.text.titleMedium),
        const SizedBox(height: 8),
        for (final a in p.attributes.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    a.key.toUpperCase(),
                    textDirection: TextDirection.ltr,
                    style: glmText(GlmType.caption, color: c.textSoft, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: a.value / 100,
                      minHeight: 8,
                      backgroundColor: c.surfaceSunk,
                      color: a.value >= 80
                          ? c.success
                          : a.value >= 65
                          ? c.gold
                          : c.warning,
                    ),
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${a.value}',
                    textAlign: TextAlign.end,
                    style: glmText(GlmType.bodyLg, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Widget _big(BuildContext context, String v, String label) => Column(
  children: [
    Text(
      v,
      style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
    ),
    Text(label, style: glmText(GlmType.caption, color: context.palette.textMuted)),
  ],
);
