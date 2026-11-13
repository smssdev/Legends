part of 'extras_screens.dart';

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
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.specialistsLead(s.days),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 12),
              for (final sp in s.list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    gold: sp.stars > 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(sp.name, style: context.text.titleMedium)),
                            if (sp.stars > 0)
                              Text(
                                '${'★' * sp.stars}${sp.endsAt != null ? '  ${l.hiredUntil(when(context, sp.endsAt!.toLocal()))}' : ''}',
                                style: TextStyle(color: context.glm.goldText),
                              ),
                          ],
                        ),
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
                                      if (!await confirm(
                                            context,
                                            l.hireConfirm(o.currency == 'coins' ? l.coinsWord(o.cost) : money(context, o.cost)),
                                          ) ||
                                          !context.mounted) {
                                        return;
                                      }
                                      await _act(context, () => ref.read(extrasRepositoryProvider).hire(leagueId, sp.type, o.stars));
                                      ref.invalidate(specialistsProvider(leagueId));
                                    },
                            ),
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
          final t = r?.tactics;
          final tactics = t == null
              ? const <String, Object>{}
              : {'plan': t.plan, 'marking': t.marking, 'tackling': t.tackling, 'trap': t.trap};
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.spyLead,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 12),
              if (s.opponent == null)
                Center(
                  child: Text(l.noNextMatch, style: TextStyle(color: p.textMuted)),
                )
              else if (r == null)
                GlmCard(
                  gold: true,
                  child: Column(
                    children: [
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
                    ],
                  ),
                )
              else
                GlmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.spyReportOn(r.club.name), style: context.text.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text('${l.formation}: ${r.formation}'),
                          if (r.fitness != null) Text('${l.fitness}: ${r.fitness}%'),
                          Text('${l.form}: ${r.form.join(' ')}', textDirection: TextDirection.ltr),
                        ],
                      ),
                      if (tactics.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          tactics.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: p.textMuted, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 10),
                      for (final pl in r.starters)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(width: 8, height: 18, color: lineColor(pl.line).bg),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(pl.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                              ),
                              Text(
                                '${pl.position} ${pl.overall}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800),
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
