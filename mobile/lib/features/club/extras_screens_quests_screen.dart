part of 'extras_screens.dart';

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
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (q.renewsAt != null)
                Text(
                  l.questsRenew(when(context, q.renewsAt!.toLocal())),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted),
                ),
              const SizedBox(height: 10),
              for (final x in q.quests)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    gold: x.complete && !x.claimed,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(switch (x.quest) {
                                'friendly' => l.questFriendly,
                                'wins' => l.questWins,
                                'stadium' => l.questStadium,
                                'training' => l.questTraining,
                                _ => l.questUnbeaten,
                              }, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                '${x.progress} / ${x.target} · ${x.coins > 0 ? l.coinsWord(x.coins) : money(context, x.money)}',
                                style: TextStyle(color: p.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (x.claimed)
                          Text(
                            l.claimed,
                            style: TextStyle(color: context.glm.successText, fontWeight: FontWeight.w700),
                          )
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
                      ],
                    ),
                  ),
                ),
            ],
          );
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
        data: (seasons) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // [Sprint 50 M22] The trophy cabinet: our cup in 3D over the league's titles.
            SizedBox(
              height: 170,
              child: GlmModel3D(
                model: 'trophy',
                label: l.honours,
                orbit: '0deg 78deg 3.4m',
                fallback: Icon(Icons.emoji_events_rounded, size: 110, color: context.palette.gold),
              ),
            ),
            const SizedBox(height: 8),
            for (final s in seasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.seasonN(s.number), style: context.text.titleMedium),
                      const SizedBox(height: 6),
                      if (s.titles.isEmpty) Text(l.noTitles, style: TextStyle(color: context.palette.textMuted)),
                      for (final t in s.titles)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            t.position == 1
                                ? '🏆'
                                : t.position == 2
                                ? '🥈'
                                : '🥉',
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            t.club,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text([t.competition == 'cup' ? l.cup : l.competitionLeague, if (t.coach != null) t.coach!].join(' · ')),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [Sprint 18 F1] A coach's profile (`/coaches/{id}`, Sprint 33): his record, his titles and his board objectives.
/// [Sprint 59 F1] A coach's profile through the generated model (`CoachProfile`).
final coachProfileProvider = FutureProvider.autoDispose.family<api.CoachProfile, int>(
  (ref, id) async => api.CoachProfile.fromJson(await ref.read(apiProvider).get('/coaches/$id')),
);

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
          final coach = j.coach;
          final r = j.record;
          final titles = j.titles;
          final obj = j.objectives;
          Widget stat(String label, Object? v) => Expanded(
            child: Column(
              children: [
                Text(
                  '${v ?? 0}',
                  style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 24, fontWeight: FontWeight.w800, color: context.glm.goldText),
                ),
                Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
              ],
            ),
          );
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              GlmCard(
                gold: true,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: p.brand,
                      child: Text(
                        coach.name.characters.take(1).toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(coach.name, style: context.text.titleLarge),
                    if (coach.accountNo case final no?) Text(l.accountNumber(no), style: TextStyle(color: p.textMuted)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        stat(l.seasonsPlayed, r.seasons),
                        stat(l.played, r.played),
                        stat(l.won, r.won),
                        stat(l.drawn, r.drawn),
                        stat(l.lost, r.lost),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionTitle(l.titles),
              if (titles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l.noTitles,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted),
                  ),
                ),
              for (final t in titles)
                ListTile(
                  leading: Text(t.position == 1 ? '🏆' : '🥈', style: const TextStyle(fontSize: 22)),
                  title: Text(
                    t.club,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${t.league} · ${l.seasonN(t.season)} · ${t.competition == 'cup' ? l.cup : l.competitionLeague}'),
                ),
              const SizedBox(height: 8),
              Text(
                l.objectivesMet(obj.met, obj.total),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}
