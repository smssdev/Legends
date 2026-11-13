part of 'account_screens.dart';

/// [X18] The coaches' ranking: titles first, then wins.
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.ranking,
      AsyncView(
        value: ref.watch(rankingProvider),
        onRetry: () => ref.invalidate(rankingProvider),
        data: (rows) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final r in rows)
              ListTile(
                leading: Text(
                  '${r.position}',
                  style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 20, fontWeight: FontWeight.w800, color: context.glm.goldText),
                ),
                title: Text(r.coach.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${l.trophiesShort(r.trophies.total)} · ${r.won}/${r.played} · ${r.rating.points}'),
                onTap: () => context.push('/coaches/${r.coach.id}'),
              ),
          ],
        ),
      ),
    );
  }
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.stats,
      AsyncView(
        value: ref.watch(statsProvider(leagueId)),
        onRetry: () => ref.invalidate(statsProvider(leagueId)),
        data: (s) {
          final p = context.palette;
          Widget list(String title, List<dynamic> rows, String key, String unit) => GlmCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: context.text.titleMedium),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(l.noStatsYet, style: TextStyle(color: p.textMuted)),
                  ),
                for (final (i, r) in rows.take(10).indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(color: p.textMuted, fontFamily: GlmFonts.numbers),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${((r as Map<dynamic, dynamic>)['player'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Text(
                          '${(r['club'] as Map<dynamic, dynamic>?)?['code'] ?? ''}  ',
                          style: TextStyle(color: p.textMuted, fontSize: 12),
                        ),
                        Text(
                          '${r[key]} $unit',
                          style: TextStyle(fontWeight: FontWeight.w800, color: context.glm.goldText),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
          final values = s['value'] as List<dynamic>? ?? const [];
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              list(l.scorers, s['scorers'] as List<dynamic>? ?? const [], 'goals', l.goalsShort),
              const SizedBox(height: 10),
              list(l.assistsTitle, s['assists'] as List<dynamic>? ?? const [], 'assists', l.assistsShort),
              const SizedBox(height: 10),
              GlmCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.squadValues, style: context.text.titleMedium),
                    for (final v in values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${(v as Map<dynamic, dynamic>)['position']}',
                                style: TextStyle(color: p.textMuted, fontFamily: GlmFonts.numbers),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${(v['club'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.start,
                              ),
                            ),
                            Text(
                              money(context, (v['value'] as num? ?? 0).toInt()),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  final title = TextEditingController(), body = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return _page(
      l.ideas,
      AsyncView(
        value: ref.watch(ideasProvider),
        onRetry: () => ref.invalidate(ideasProvider),
        data: (d) {
          final p = context.palette;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final poll in d.polls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    gold: poll.state == 'open',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(poll.question, style: context.text.titleMedium),
                        if (poll.body case final b?) Text(b, style: TextStyle(color: p.textMuted)),
                        for (final o in poll.options)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(poll.myVote == o.id ? Icons.radio_button_checked : Icons.radio_button_off, color: p.gold),
                            title: Text(o.label),
                            trailing: o.votes == null ? null : Text(l.votes(o.votes!), style: TextStyle(color: p.textMuted)),
                            onTap: poll.state != 'open' || poll.myVote != null
                                ? null
                                : () async {
                                    await _try(context, () => api.post('/ideas/polls/${poll.id}/vote', {'option_id': o.id}));
                                    ref.invalidate(ideasProvider);
                                  },
                          ),
                      ],
                    ),
                  ),
                ),
              GlmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.ideasLead(d.leftToday), style: TextStyle(color: p.textMuted)),
                    TextField(
                      controller: title,
                      maxLength: 120,
                      decoration: InputDecoration(labelText: l.articleTitle),
                    ),
                    TextField(
                      controller: body,
                      maxLength: 2000,
                      minLines: 3,
                      maxLines: 8,
                      decoration: InputDecoration(labelText: l.articleBody),
                    ),
                    GlmButton(
                      label: l.suggest,
                      onPressed: d.leftToday == 0
                          ? null
                          : () async {
                              final r = await _try(
                                context,
                                () => api.post('/ideas/suggestions', {'title': title.text.trim(), 'body': body.text.trim()}),
                              );
                              if (r != null && context.mounted) {
                                showGlmToast(context, l.suggestionSent);
                                title.clear();
                                body.clear();
                              }
                              ref.invalidate(ideasProvider);
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              for (final sgg in d.suggestions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sgg.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    [
                      switch (sgg.status) {
                        'accepted' => l.statusAccepted,
                        'built' => l.statusBuilt,
                        'rejected' => l.statusRejected,
                        _ => l.statusPending,
                      },
                      if (sgg.coins > 0) l.coinsWord(sgg.coins),
                      ?sgg.reply,
                    ].join(' · '),
                  ),
                ),
              if (d.honours.isNotEmpty) ...[
                SectionTitle(l.honourRoll),
                for (final h in d.honours)
                  ListTile(
                    dense: true,
                    leading: Text(
                      '${h.rank}',
                      style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
                    ),
                    title: Text(h.user.name),
                    trailing: Text('${h.count}'),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
