import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/motion.dart';
import '../../ui/widgets/glm_background.dart';
import 'team_data.dart';

/// [Sprint 17 F1] The squad by line (the web's Squad): each player's position badge in his line's colour, his rating,
/// age, fitness and role, and who cannot play; a tap opens his card.
class SquadScreen extends ConsumerWidget {
  const SquadScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.squad)),
      body: GlmBackground(
        wide: true,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(teamProvider(leagueId).future),
          child: AsyncView(
            value: ref.watch(teamProvider(leagueId)),
            onRetry: () => ref.invalidate(teamProvider(leagueId)),
            data: (team) {
              final lines = {'gk': l.lineGk, 'def': l.lineDef, 'mid': l.lineMid, 'att': l.lineAtt};
              return ListView(padding: const EdgeInsets.all(12), children: [
                Row(children: [
                  Text(l.morale(team.morale), style: TextStyle(color: context.palette.textSoft, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${l.squadValue}: ${money(context, team.squadValue)}', textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.palette.textMuted))),
                ]),
                for (final e in lines.entries) ...[
                  SectionTitle(e.value),
                  // [2026-11-06] Two players a row in landscape.
                  LayoutBuilder(builder: (context, box) {
                    final cols = box.maxWidth >= 640 ? 2 : 1;
                    final w = (box.maxWidth - (cols - 1) * 8) / cols;
                    return Wrap(spacing: 8, children: [
                      for (final (i, p) in team.players.where((p) => p.line == e.key).indexed)
                        SizedBox(width: w, child: FadeSlideIn(index: i, child: PlayerRow(p, onTap: () => showPlayerCard(context, p)))),
                    ]);
                  }),
                ],
              ]);
            },
          ),
        ),
      ),
    );
  }
}

/// Money in short Western digits in every language (3.5M), as the game writes numbers (Sprint 30).
String money(BuildContext context, int v) => NumberFormat.compact(locale: 'en').format(v);

({Color bg, Color fg}) lineColor(String line) => switch (line) { 'gk' => GlmLine.gk, 'def' => GlmLine.def, 'mid' => GlmLine.mid, _ => GlmLine.att };

Color fitnessColor(int f) => glmFitness.firstWhere((x) => f >= x.min, orElse: () => glmFitness.last).color;

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? c.gold : Colors.white.withValues(alpha: context.glm.day ? 0 : .06)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children: [
                RatingBadge(p.overall, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      PositionChip(p.position, p.line),
                      const SizedBox(width: 8),
                      // Player names stay in English in every language (decision 2026-11-01).
                      Flexible(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                        child: Text(
                          !p.available ? (p.injured > 0 ? '🩹 ${l.injuredFor(p.injured)}' : '🟥 ${l.suspendedFor(p.suspended)}') : '${l.age(p.age)} · ${starter ? l.starter : p.role == 'bench' ? l.bench : l.reserve}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.available ? (starter ? context.glm.successText : c.textMuted) : context.glm.liveText, fontSize: 12, fontWeight: starter ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                      Text('${p.fitness}%', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 13, color: c.textMuted)),
                      const SizedBox(width: 6),
                      LevelBar(p.fitness / 100, color: fitnessColor(p.fitness)),
                    ]),
                  ]),
                ),
                ?trailing,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A player's card: his numbers and each attribute as a bar.
Future<void> showPlayerCard(BuildContext context, Player p) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.palette.panel,
      builder: (context) {
        final l = L.of(context);
        final c = context.palette;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(p.name, textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text([p.position, l.age(p.age), if (p.nationality != null) p.nationality!].join(' · '), textAlign: TextAlign.center, style: TextStyle(color: c.textMuted)),
              const SizedBox(height: 14),
              Row(children: [
                for (final (v, label) in [('${p.overall}', l.ratingWord), ('${p.potential}', l.potentialWord), ('${p.fitness}%', l.fitness), (money(context, p.value), l.value)])
                  Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: _big(context, v, label))),
              ]),
              const SizedBox(height: 16),
              Text(l.attributes, style: context.text.titleMedium),
              const SizedBox(height: 8),
              for (final a in p.attributes.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(width: 90, child: Text(a.key.toUpperCase(), textDirection: TextDirection.ltr, style: TextStyle(color: c.textSoft, fontWeight: FontWeight.w700, fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: a.value / 100, minHeight: 8, backgroundColor: c.surfaceSunk, color: a.value >= 80 ? c.success : a.value >= 65 ? c.gold : c.warning),
                      ),
                    ),
                    SizedBox(width: 34, child: Text('${a.value}', textAlign: TextAlign.end, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16))),
                  ]),
                ),
            ]),
          ),
        );
      },
    );

Widget _big(BuildContext context, String v, String label) => Column(children: [
      Text(v, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 26, fontWeight: FontWeight.w800, color: context.glm.goldText)),
      Text(label, style: TextStyle(color: context.palette.textMuted, fontSize: 11)),
    ]);
