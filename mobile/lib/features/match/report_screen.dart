import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_card.dart';
import 'live_screen.dart' show EventLine;
import 'match_data.dart';

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
      appBar: AppBar(title: Text(l.matchReport)),
      body: GlmBackground(
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
    final result = switch (r.result) { 'win' => l.resultWin, 'loss' => l.resultLoss, _ => l.resultDraw };
    final color = switch (r.result) { 'win' => context.glm.successText, 'loss' => context.glm.liveText, _ => context.glm.goldText };
    const gap = SizedBox(height: 12);
    Widget title(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: context.text.titleMedium));
    Widget note(({String title, String text, String big}) n) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 64, child: Text(n.big, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 22, fontWeight: FontWeight.w800, color: context.glm.goldText))),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(n.text, style: TextStyle(color: p.textMuted, fontSize: 13)),
            ])),
          ]),
        );
    final stats = [
      ('possession', l.possession), ('shots', l.shots), ('on_target', l.onTarget), ('corners', l.corners), ('fouls', l.fouls), ('saves', l.saves),
    ].where((s) => r.stats['home']!.containsKey(s.$1));
    return ListView(padding: const EdgeInsets.all(12), children: [
      GlmCard(
        gold: true,
        child: Column(children: [
          Text('${r.score.$1} - ${r.score.$2}', textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 44, fontWeight: FontWeight.w800, color: p.text)),
          if (r.side != null) Text(result, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          if (r.motm != null) ...[
            const SizedBox(height: 8),
            Text('${l.manOfMatch}: ${r.motm}', style: TextStyle(color: p.textMuted)),
          ],
        ]),
      ),
      if (r.verdict.isNotEmpty) ...[
        gap,
        GlmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final v in r.verdict) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text.rich(TextSpan(children: [
            TextSpan(text: '${v.tag}  ', style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800)),
            TextSpan(text: v.text),
          ]))),
        ])),
      ],
      if (r.reasons.isNotEmpty) ...[
        gap,
        GlmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [title(l.whyResult), for (final n in r.reasons) note(n)])),
      ],
      if (r.improve != null) ...[
        gap,
        GlmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [title(l.toImprove), note(r.improve!)])),
      ],
      if (stats.isNotEmpty) ...[
        gap,
        GlmCard(child: Column(children: [
          for (final (key, label) in stats)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                SizedBox(width: 48, child: Text('${r.stats['home']![key]}${key == 'possession' ? '%' : ''}', textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 18, fontWeight: FontWeight.w800))),
                Expanded(child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted))),
                SizedBox(width: 48, child: Text('${r.stats['away']![key] ?? 0}${key == 'possession' ? '%' : ''}', textAlign: TextAlign.end, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 18, fontWeight: FontWeight.w800))),
              ]),
            ),
        ])),
      ],
      if (r.moments.isNotEmpty) ...[
        gap,
        title(l.keyMoments),
        for (final m in r.moments) EventLine(m),
      ],
      if (r.ratings.values.any((v) => v.isNotEmpty)) ...[
        gap,
        title(l.bestPlayers),
        GlmCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final side in ['home', 'away'])
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final pl in r.ratings[side]!.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  child: Row(children: [
                    Expanded(child: Text(pl.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr)),
                    Text((pl.rating / 100).toStringAsFixed(1), style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText)),
                  ]),
                ),
            ])),
        ])),
      ],
      const SizedBox(height: 24),
    ]);
  }
}
