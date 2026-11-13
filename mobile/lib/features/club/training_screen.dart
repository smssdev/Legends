import '../../ui/widgets/glm_icon.dart';
import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;
import '../money/finance_screen.dart' show confirm;
import 'extras_data.dart';
import 'squad_screen.dart' show money, lineColor;

String _lineName(L l, String line) => switch (line) {
  'gk' => l.lineGk,
  'def' => l.lineDef,
  'mid' => l.lineMid,
  _ => l.lineAtt,
};

String _span(L l, int minutes) => minutes >= 120 ? l.hours((minutes / 60).round()) : l.minutes(minutes);

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final repo = ref.read(extrasRepositoryProvider);
    final finishCoins = ref.watch(pricesProvider).value?['finish_training'];
    Future<void> run(Future<void> Function() a) async {
      await tryAction(context, a);
      ref.invalidate(trainingProvider(leagueId));
    }

    return screenPage(
      l.training,
      AsyncView(
        value: ref.watch(trainingProvider(leagueId)),
        onRetry: () => ref.invalidate(trainingProvider(leagueId)),
        data: (t) {
          final p = context.palette;
          return RefreshIndicator(
            color: p.gold,
            onRefresh: () => ref.refresh(trainingProvider(leagueId).future),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  l.trainingLead,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted),
                ),
                Text(
                  l.sessionCost(money(context, t.cost), _span(l, t.intervalMinutes)),
                  textAlign: TextAlign.center,
                  style: glmText(GlmType.caption, color: p.textMuted),
                ),
                const SizedBox(height: 12),
                for (final s in t.slots)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 24,
                                decoration: BoxDecoration(color: lineColor(s.line).bg, borderRadius: BorderRadius.circular(4)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_lineName(l, s.line), style: context.text.titleMedium)),
                              if (s.coachStars > 0)
                                Text(l.lineCoach(s.coachName, s.coachStars), style: glmText(GlmType.caption, color: context.glm.goldText)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (s.player == null)
                            Text(l.nobodyTraining, style: TextStyle(color: p.textMuted))
                          else ...[
                            Text(
                              '${s.player!.name}  ${s.player!.rating}/${s.player!.potential}',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.start,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: s.player!.sessions == 0 ? 0 : s.player!.progress / s.player!.sessions,
                                minHeight: 8,
                                color: p.gold,
                                backgroundColor: p.surfaceRaised,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                l.sessionsDone(s.sessionsDone),
                                if (s.player!.maxed) l.maxed,
                                if (s.nextAt != null) l.nextSession(when(context, s.nextAt!.toLocal())),
                              ].join(' · '),
                              style: glmText(GlmType.caption, color: p.textMuted),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: GlmButton(
                                  label: l.pickToTrain,
                                  variant: GlmButtonVariant.outline,
                                  onPressed: () => _pick(context, ref, t, s, run),
                                ),
                              ),
                              if (s.player != null) ...[
                                const SizedBox(width: 8),
                                GlmButton(
                                  label: l.stopTraining,
                                  variant: GlmButtonVariant.quiet,
                                  onPressed: () => run(() => repo.stopTraining(leagueId, s.line)),
                                ),
                              ],
                            ],
                          ),
                          if (s.player != null && finishCoins != null) ...[
                            const SizedBox(height: 8),
                            GlmButton(
                              label: l.finishNow(finishCoins),
                              variant: GlmButtonVariant.quiet,
                              onPressed: () async {
                                if (await confirm(context, l.finishNowConfirm(finishCoins))) {
                                  await run(() => repo.finishTraining(leagueId, s.line));
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    TrainingView t,
    TrainingSlot s,
    Future<void> Function(Future<void> Function()) run,
  ) async {
    final l = L.of(context);
    final rec = t.recommended[s.line];
    final players = [
      for (final p in t.players)
        if (p.line == s.line && !p.maxed) p,
    ]..sort((a, b) => (b.id == rec ? 1 : 0) - (a.id == rec ? 1 : 0));
    final picked = await showModalBottomSheet<Trainee>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .7),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final p in players)
                ListTile(
                  title: Text(
                    p.name,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Row(
                    children: [
                      Text('${p.position} · ${p.age} · ${p.rating}/${p.potential}'),
                      if (p.injured) ...[const Text(' · '), const GlmEventMark('injury', size: 14)],
                    ],
                  ),
                  trailing: p.id == rec
                      ? Text(
                          l.recommended,
                          style: TextStyle(color: ctx.glm.goldText, fontWeight: FontWeight.w800),
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, p),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await run(() => ref.read(extrasRepositoryProvider).train(leagueId, picked.id, replace: s.player != null));
  }
}
