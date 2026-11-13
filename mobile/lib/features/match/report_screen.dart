import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/widgets/console.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/motion.dart';
import '../../ui/widgets/stadium.dart';
import 'live_screen.dart' show EventLine;
import 'match_data.dart';
import '../leagues/shell.dart';

/// [Sprint 17 F2] After the whistle: the coach's report (why he won or lost, what to improve, his assistant's verdict,
/// the numbers, the key moments and the best players), or the quick recap for a member who coaches neither side.
class MatchReportScreen extends ConsumerWidget {
  const MatchReportScreen({super.key, required this.matchId, required this.coach});

  final int matchId;
  final bool coach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final key = (matchId, coach);
    return Scaffold(
      appBar: GameBar(title: Text(l.matchReport)),
      body: GlmBackground(
        wide: true,
        child: AsyncView(
          value: ref.watch(reportProvider(key)),
          onRetry: () => ref.invalidate(reportProvider(key)),
          data: (r) => _Report(r),
        ),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report(this.r);

  final MatchReport r;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final result = switch (r.result) {
      'win' => l.resultWin,
      'loss' => l.resultLoss,
      _ => l.resultDraw,
    };
    final color = switch (r.result) {
      'win' => context.glm.successText,
      'loss' => context.glm.liveText,
      _ => context.glm.goldText,
    };
    Widget title(String t, IconData icon) => GameHeader(t, icon: icon);
    Widget note(({String title, String text, String big}) n) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            margin: const EdgeInsetsDirectional.only(end: 12),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: p.gold.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
            child: Text(
              n.big,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(n.text, style: glmText(GlmType.caption, color: p.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
    final stats = [
      ('possession', l.possession),
      ('shots', l.shots),
      ('on_target', l.onTarget),
      ('corners', l.corners),
      ('fouls', l.fouls),
      ('saves', l.saves),
    ].where((s) => r.stats['home']!.containsKey(s.$1));
    // [2026-11-06, stage 3] The score on the night stadium, the result as a lit pill, the man of the match with his star.
    final hero = HeroFrame(
      edge: r.result == 'win'
          ? p.success
          : r.result == 'loss'
          ? p.live
          : p.gold,
      child: StadiumBackdrop(
        tint: r.result == 'win'
            ? p.success
            : r.result == 'loss'
            ? p.live
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              Text(
                '${r.score.$1}  -  ${r.score.$2}',
                textDirection: TextDirection.ltr,
                style: glmText(
                  GlmType.displayLg,
                  fontFamily: GlmFonts.numbers,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: .5), blurRadius: 12)],
                ),
              ),
              if (r.side != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: ShapeDecoration(
                    color: color.withValues(alpha: .18),
                    shape: GlmCut.shape(GlmCut.chip + 2, side: BorderSide(color: color.withValues(alpha: .5))),
                  ),
                  child: Text(
                    result,
                    style: glmText(GlmType.bodyLg, color: color, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              if (r.motm != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  // [Sprint 50 M16] The man of the match's gold card.
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [p.goldLight, p.gold, p.goldDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: p.gold.withValues(alpha: .4), blurRadius: 16)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: p.onGold, size: 18),
                      const SizedBox(width: 6),
                      Text('${l.manOfMatch}: ', style: glmText(GlmType.caption, color: p.onGold)),
                      Flexible(
                        child: Text(
                          r.motm!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: p.onGold, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    // [Sprint 50 M16] The report's two teams side by side: your side first (in mint), the opponent after (in orange),
    // each figure on the site's two-colour bar.
    final mine = r.side ?? 'home', theirs = mine == 'home' ? 'away' : 'home';
    Widget statRow(String key, String label) {
      final h = r.stats[mine]![key] ?? 0, a = r.stats[theirs]![key] ?? 0;
      String v(num x) => '$x${key == 'possession' ? '%' : ''}';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: GlmDualCompareBar(label: label, mine: h, theirs: a, mineText: v(h), theirsText: v(a)),
      );
    }

    final start = <Widget>[
      hero,
      if (stats.isNotEmpty) ...[
        title(l.matchStats, Icons.bar_chart_rounded),
        GlmCard(child: Column(children: [for (final (key, label) in stats) statRow(key, label)])),
      ],
      if (r.ratings.values.any((v) => v.isNotEmpty)) ...[
        title(l.bestPlayers, Icons.star_rounded),
        GlmCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final side in [mine, theirs])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          side == mine ? l.yourSide : l.theirSide,
                          style: glmText(GlmType.caption, fontWeight: FontWeight.w800, color: side == mine ? p.brandLight : p.warning),
                        ),
                      ),
                      for (final pl in r.ratings[side]!.take(4))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pl.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: p.gold.withValues(alpha: .16), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  (pl.rating / 100).toStringAsFixed(1),
                                  style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
    final end = <Widget>[
      if (r.verdict.isNotEmpty)
        GlmCard(
          accent: p.gold,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(Icons.record_voice_over_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final v in r.verdict)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${v.tag}  ',
                                style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800),
                              ),
                              TextSpan(text: v.text),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (r.reasons.isNotEmpty) ...[
        title(l.whyResult, Icons.insights_rounded),
        GlmCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final n in r.reasons) note(n)]),
        ),
      ],
      if (r.improve != null) ...[title(l.toImprove, Icons.trending_up_rounded), GlmCard(accent: p.success, child: note(r.improve!))],
      if (r.moments.isNotEmpty) ...[
        title(l.keyMoments, Icons.bolt_rounded),
        for (final (i, m) in r.moments.indexed) FadeSlideIn(index: i, child: EventLine(m)),
      ],
    ];
    return GamePanes(start: start, end: end, startFlex: 1, endFlex: 1);
  }
}
