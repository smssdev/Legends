import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/widgets/console.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/widgets.dart' show when;
import '../money/finance_screen.dart' show confirm;
import 'extras_data.dart';
import 'squad_screen.dart' show money, lineColor;
import '../leagues/shell.dart';

/// [Sprint 18 F1] The club's other screens in the app: training, the specialists, the spy, the weekly quests and
/// the league's honours. They show what the server sends and send the coach's choice; a refusal shows its reason.
Future<void> _act(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
  }
}

String _lineName(L l, String line) => switch (line) { 'gk' => l.lineGk, 'def' => l.lineDef, 'mid' => l.lineMid, _ => l.lineAtt };

String _span(L l, int minutes) => minutes >= 120 ? l.hours((minutes / 60).round()) : l.minutes(minutes);

Widget _scaffold(String title, Widget body) => Scaffold(appBar: GameBar(title: Text(title)), body: GlmBackground(child: body));

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final repo = ref.read(extrasRepositoryProvider);
    final finishCoins = ref.watch(pricesProvider).value?['finish_training'];
    Future<void> run(Future<void> Function() a) async {
      await _act(context, a);
      ref.invalidate(trainingProvider(leagueId));
    }

    return _scaffold(
      l.training,
      AsyncView(
        value: ref.watch(trainingProvider(leagueId)),
        onRetry: () => ref.invalidate(trainingProvider(leagueId)),
        data: (t) {
          final p = context.palette;
          return RefreshIndicator(
            color: p.gold,
            onRefresh: () => ref.refresh(trainingProvider(leagueId).future),
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Text(l.trainingLead, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
              Text(l.sessionCost(money(context, t.cost), _span(l, t.intervalMinutes)), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              for (final s in t.slots)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Container(width: 10, height: 24, decoration: BoxDecoration(color: lineColor(s.line).bg, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_lineName(l, s.line), style: context.text.titleMedium)),
                        if (s.coachStars > 0) Text(l.lineCoach(s.coachName, s.coachStars), style: TextStyle(color: context.glm.goldText, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      if (s.player == null)
                        Text(l.nobodyTraining, style: TextStyle(color: p.textMuted))
                      else ...[
                        Text('${s.player!.name}  ${s.player!.rating}/${s.player!.potential}', textDirection: TextDirection.ltr, textAlign: TextAlign.start,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: s.player!.sessions == 0 ? 0 : s.player!.progress / s.player!.sessions, minHeight: 8, color: p.gold, backgroundColor: p.surfaceRaised),
                        ),
                        const SizedBox(height: 4),
                        Text([l.sessionsDone(s.sessionsDone), if (s.player!.maxed) l.maxed, if (s.nextAt != null) l.nextSession(when(context, s.nextAt!.toLocal()))].join(' · '),
                            style: TextStyle(color: p.textMuted, fontSize: 12)),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: GlmButton(label: l.pickToTrain, variant: GlmButtonVariant.outline, onPressed: () => _pick(context, ref, t, s, run))),
                        if (s.player != null) ...[
                          const SizedBox(width: 8),
                          GlmButton(label: l.stopTraining, variant: GlmButtonVariant.quiet, onPressed: () => run(() => repo.stopTraining(leagueId, s.line))),
                        ],
                      ]),
                      if (s.player != null && finishCoins != null) ...[
                        const SizedBox(height: 8),
                        GlmButton(
                          label: l.finishNow(finishCoins),
                          variant: GlmButtonVariant.quiet,
                          onPressed: () async {
                            if (await confirm(context, l.finishNowConfirm(finishCoins))) await run(() => repo.finishTraining(leagueId, s.line));
                          },
                        ),
                      ],
                    ]),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, TrainingView t, TrainingSlot s, Future<void> Function(Future<void> Function()) run) async {
    final l = L.of(context);
    final rec = t.recommended[s.line];
    final players = [for (final p in t.players) if (p.line == s.line && !p.maxed) p]..sort((a, b) => (b.id == rec ? 1 : 0) - (a.id == rec ? 1 : 0));
    final picked = await showModalBottomSheet<Trainee>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .7),
          child: ListView(shrinkWrap: true, children: [
            for (final p in players)
              ListTile(
                title: Text(p.name, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${p.position} · ${p.age} · ${p.rating}/${p.potential}${p.injured ? ' · 🩹' : ''}'),
                trailing: p.id == rec ? Text(l.recommended, style: TextStyle(color: ctx.glm.goldText, fontWeight: FontWeight.w800)) : null,
                onTap: () => Navigator.pop(ctx, p),
              ),
          ]),
        ),
      ),
    );
    if (picked != null) await run(() => ref.read(extrasRepositoryProvider).train(leagueId, picked.id, replace: s.player != null));
  }
}

class SpecialistsScreen extends ConsumerWidget {
  const SpecialistsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _scaffold(
      l.specialists,
      AsyncView(
        value: ref.watch(specialistsProvider(leagueId)),
        onRetry: () => ref.invalidate(specialistsProvider(leagueId)),
        data: (s) {
          final p = context.palette;
          return ListView(padding: const EdgeInsets.all(12), children: [
            Text(l.specialistsLead(s.days), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            const SizedBox(height: 12),
            for (final sp in s.list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlmCard(
                  gold: sp.stars > 0,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(child: Text(sp.name, style: context.text.titleMedium)),
                      if (sp.stars > 0) Text('${'★' * sp.stars}${sp.endsAt != null ? '  ${l.hiredUntil(when(context, sp.endsAt!.toLocal()))}' : ''}', style: TextStyle(color: context.glm.goldText)),
                    ]),
                    const SizedBox(height: 6),
                    for (final o in sp.offers)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('★' * o.stars, style: TextStyle(color: p.gold)),
                        subtitle: Text(o.effect),
                        trailing: GlmButton(
                          label: '${l.hire} ${o.currency == 'coins' ? l.coinsWord(o.cost) : money(context, o.cost)}',
                          variant: GlmButtonVariant.outline,
                          onPressed: sp.stars > 0
                              ? null
                              : () async {
                                  if (!await confirm(context, l.hireConfirm(o.currency == 'coins' ? l.coinsWord(o.cost) : money(context, o.cost))) || !context.mounted) return;
                                  await _act(context, () => ref.read(extrasRepositoryProvider).hire(leagueId, sp.type, o.stars));
                                  ref.invalidate(specialistsProvider(leagueId));
                                },
                        ),
                      ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class SpyScreen extends ConsumerWidget {
  const SpyScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _scaffold(
      l.spy,
      AsyncView(
        value: ref.watch(spyProvider(leagueId)),
        onRetry: () => ref.invalidate(spyProvider(leagueId)),
        data: (s) {
          final p = context.palette;
          final r = s.report;
          final cost = s.currency == 'coins' ? l.coinsWord(s.cost) : money(context, s.cost);
          final tactics = (r?['tactics'] as Map?) ?? const {};
          return ListView(padding: const EdgeInsets.all(12), children: [
            Text(l.spyLead, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            const SizedBox(height: 12),
            if (s.opponent == null)
              Center(child: Text(l.noNextMatch, style: TextStyle(color: p.textMuted)))
            else if (r == null)
              GlmCard(
                gold: true,
                child: Column(children: [
                  Text(s.opponent!, textDirection: TextDirection.ltr, style: context.text.titleLarge),
                  const SizedBox(height: 10),
                  GlmButton(
                    label: l.sendSpy(cost),
                    onPressed: () async {
                      if (!await confirm(context, l.sendSpy(cost)) || !context.mounted) return;
                      await _act(context, () => ref.read(extrasRepositoryProvider).sendSpy(leagueId));
                      ref.invalidate(spyProvider(leagueId));
                    },
                  ),
                ]),
              )
            else
              GlmCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l.spyReportOn('${(r['club'] as Map?)?['name'] ?? s.opponent}'), style: context.text.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(spacing: 16, runSpacing: 6, children: [
                    Text('${l.formation}: ${r['formation'] ?? '—'}'),
                    if (r['fitness'] != null) Text('${l.fitness}: ${r['fitness']}%'),
                    Text('${l.form}: ${((r['form'] as List?) ?? const []).join(' ')}', textDirection: TextDirection.ltr),
                  ]),
                  if (tactics.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(tactics.entries.map((e) => '${e.key}: ${e.value}').join(' · '), textDirection: TextDirection.ltr, style: TextStyle(color: p.textMuted, fontSize: 12)),
                  ],
                  const SizedBox(height: 10),
                  for (final pl in (r['starters'] as List? ?? const []))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Container(width: 8, height: 18, color: lineColor('${(pl as Map)['line']}').bg),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${pl['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
                        Text('${pl['position']} ${pl['overall']}', textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _scaffold(
      l.quests,
      AsyncView(
        value: ref.watch(questsProvider(leagueId)),
        onRetry: () => ref.invalidate(questsProvider(leagueId)),
        data: (q) {
          final p = context.palette;
          return ListView(padding: const EdgeInsets.all(12), children: [
            if (q.renewsAt != null) Text(l.questsRenew(when(context, q.renewsAt!.toLocal())), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            const SizedBox(height: 10),
            for (final x in q.quests)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlmCard(
                  gold: x.complete && !x.claimed,
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(switch (x.quest) {
                          'friendly' => l.questFriendly, 'wins' => l.questWins, 'stadium' => l.questStadium, 'training' => l.questTraining, _ => l.questUnbeaten,
                        }, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${x.progress} / ${x.target} · ${x.coins > 0 ? l.coinsWord(x.coins) : money(context, x.money)}', style: TextStyle(color: p.textMuted)),
                      ]),
                    ),
                    if (x.claimed)
                      Text(l.claimed, style: TextStyle(color: context.glm.successText, fontWeight: FontWeight.w700))
                    else
                      GlmButton(
                        label: l.claim,
                        onPressed: x.complete
                            ? () async {
                                await _act(context, () => ref.read(extrasRepositoryProvider).claimQuest(leagueId, x.quest));
                                ref.invalidate(questsProvider(leagueId));
                              }
                            : null,
                      ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class HonoursScreen extends ConsumerWidget {
  const HonoursScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _scaffold(
      l.honours,
      AsyncView(
        value: ref.watch(honoursProvider(leagueId)),
        onRetry: () => ref.invalidate(honoursProvider(leagueId)),
        data: (seasons) => ListView(padding: const EdgeInsets.all(12), children: [
          // [Sprint 50 M22] The trophy cabinet: our cup in 3D over the league's titles.
          SizedBox(height: 170, child: GlmModel3D(model: 'trophy', label: l.honours, orbit: '0deg 78deg 3.4m', fallback: Icon(Icons.emoji_events_rounded, size: 110, color: context.palette.gold))),
          const SizedBox(height: 8),
          for (final s in seasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlmCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l.seasonN(s.number), style: context.text.titleMedium),
                  const SizedBox(height: 6),
                  if (s.titles.isEmpty) Text(l.noTitles, style: TextStyle(color: context.palette.textMuted)),
                  for (final t in s.titles)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(t.position == 1 ? '🏆' : t.position == 2 ? '🥈' : '🥉', style: const TextStyle(fontSize: 22)),
                      title: Text(t.club, textDirection: TextDirection.ltr, textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text([t.competition == 'cup' ? l.cup : l.competitionLeague, if (t.coach != null) t.coach!].join(' · ')),
                    ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

/// [Sprint 18 F1] A coach's profile (`/coaches/{id}`, Sprint 33): his record, his titles and his board objectives.
final coachProfileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) => ref.read(apiProvider).get('/coaches/$id'));

class CoachProfileScreen extends ConsumerWidget {
  const CoachProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _scaffold(
      l.coachProfile,
      AsyncView(
        value: ref.watch(coachProfileProvider(userId)),
        onRetry: () => ref.invalidate(coachProfileProvider(userId)),
        data: (j) {
          final p = context.palette;
          final coach = j['coach'] as Map? ?? const {};
          final r = j['record'] as Map? ?? const {};
          final titles = j['titles'] as List? ?? const [];
          final obj = j['objectives'] as Map? ?? const {};
          Widget stat(String label, Object? v) => Expanded(
                child: Column(children: [
                  Text('${v ?? 0}', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 24, fontWeight: FontWeight.w800, color: context.glm.goldText)),
                  Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
                ]),
              );
          return ListView(padding: const EdgeInsets.all(12), children: [
            GlmCard(
              gold: true,
              child: Column(children: [
                CircleAvatar(radius: 32, backgroundColor: p.brand, child: Text('${coach['name'] ?? ''}'.characters.take(1).toString(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))),
                const SizedBox(height: 8),
                Text('${coach['name'] ?? ''}', style: context.text.titleLarge),
                if (coach['account_no'] != null) Text(l.accountNumber(coach['account_no'] as int), style: TextStyle(color: p.textMuted)),
                const SizedBox(height: 14),
                Row(children: [stat(l.seasonsPlayed, r['seasons']), stat(l.played, r['played']), stat(l.won, r['won']), stat(l.drawn, r['drawn']), stat(l.lost, r['lost'])]),
              ]),
            ),
            const SizedBox(height: 12),
            SectionTitle(l.titles),
            if (titles.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(l.noTitles, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted))),
            for (final t in titles)
              ListTile(
                leading: Text((t as Map)['position'] == 1 ? '🏆' : '🥈', style: const TextStyle(fontSize: 22)),
                title: Text('${t['club']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${t['league']} · ${l.seasonN(t['season'] as int? ?? 1)} · ${t['competition'] == 'cup' ? l.cup : l.competitionLeague}'),
              ),
            const SizedBox(height: 8),
            Text(l.objectivesMet(obj['met'] as int? ?? 0, obj['total'] as int? ?? 0), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
          ]);
        },
      ),
    );
  }
}
