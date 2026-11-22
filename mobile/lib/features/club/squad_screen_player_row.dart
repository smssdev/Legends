part of 'squad_screen.dart';

class PlayerRow extends StatelessWidget {
  const PlayerRow(this.p, {super.key, this.onTap, this.selected = false, this.trailing, this.dense = false});

  /// [Sprint 73 D3] A row 48 high (a whole touch, no more) for a list in a short column: the lineup's bench.
  final bool dense;

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
      padding: EdgeInsets.only(bottom: dense ? 4 : 6),
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
            constraints: BoxConstraints(minHeight: dense ? 48 : 60),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 8),
              child: LayoutBuilder(
                builder: (context, row) {
                  final tight = GlmFit.isTightRow(row.maxWidth);
                  return Row(
                    children: [
                      RatingBadge(p.overall, size: dense ? 34 : 42),
                      SizedBox(width: dense ? 8 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // [Sprint 73 D3] In a very tight column (a 640 phone's bench) the name alone: the chip beside it
                                // left no room for even a last name.
                                if (!tight) ...[PositionChip(p.position, p.line), const SizedBox(width: 8)],
                                // Player names stay in English in every language (decision 2026-11-01).
                                // [Sprint 72 R6] One line: whole, then «G. Last», then the last name; never broken in a word.
                                Expanded(
                                  child: PlayerName(p.name, style: glmText(GlmType.body, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                            SizedBox(height: dense ? 1 : 4),
                            LayoutBuilder(
                              builder: (context, box) {
                                final roomy = GlmFit.hasRowExtras(box.maxWidth);
                                return Row(
                                  children: [
                                    // [Sprint 63 G5] Why he cannot play, by the set's mark (it was an emoji).
                                    if (!p.available) ...[
                                      GlmEventMark(p.injured > 0 ? 'injury' : 'red', size: 14),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        !p.available
                                            ? (p.injured > 0 ? l.injuredFor(p.injured) : l.suspendedFor(p.suspended))
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
                                      style: glmText(GlmType.caption, fontFamily: GlmFonts.numbers, color: fitnessColor(p.fitness)),
                                    ),
                                    // [Sprint 72 R6] The bar beside the figure only where the row has room for it.
                                    if (roomy) ...[const SizedBox(width: 6), LevelBar(p.fitness / 100, color: fitnessColor(p.fitness))],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  );
                },
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
/// [X114] [action] under the card (a sale, an offer), built in the sheet's own context.
Future<void> showPlayerCard(BuildContext context, Player p, {Widget? Function(BuildContext context)? action}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: context.palette.panel,
  builder: (context) {
    final a = action?.call(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlayerCardBody(p),
            if (a != null) ...[const SizedBox(height: GlmSpace.md), a],
          ],
        ),
      ),
    );
  },
);

/// [Sprint 60 F4] The card beside the squad's table (the approved draft's side panel): the table stays in view, and a
/// tap on another row puts that player here.
class PlayerCardPanel extends StatelessWidget {
  const PlayerCardPanel({super.key, required this.player, required this.close, this.action});

  final Player player;
  final VoidCallback close;

  /// [X114] Under the card, kept in sight: his sale (mine) or an offer for him (another coach's).
  final Widget? action;

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
          if (action != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: action),
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
