part of 'matchday_screens.dart';

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return _page(
      l.contracts,
      AsyncView(
        value: ref.watch(contractsProvider(leagueId)),
        onRetry: () => ref.invalidate(contractsProvider(leagueId)),
        data: (c) {
          final p = context.palette;
          final season = c['season'] as int? ?? 1;
          final max = c['max_seasons'] as int? ?? 3;
          Future<void> act(Future<Object?> Function() a) async {
            await _try(context, a);
            ref.invalidate(contractsProvider(leagueId));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.contractsLead(
                  money(context, (c['wages_per_round'] as num? ?? 0).toInt()),
                  money(context, (c['cap_per_round'] as num? ?? 0).toInt()),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 8),
              GlmButton(
                label: l.renewEnding,
                variant: GlmButtonVariant.outline,
                onPressed: () => act(() => api.post('/leagues/$leagueId/team/contracts/renew-ending')),
              ),
              const SizedBox(height: 8),
              for (final x in (c['players'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${x['name']}',
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.start,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              l.untilSeason(x['until'] as int? ?? 0),
                              style: TextStyle(
                                color: (x['until'] as int? ?? 0) <= season ? context.glm.liveText : p.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${x['position']} · ${x['age']} · ${money(context, (x['wage'] as num? ?? 0).toInt())}',
                          style: TextStyle(color: p.textMuted, fontSize: 12),
                        ),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (var n = 1; n <= max - ((x['until'] as int? ?? season) - season); n++)
                              TextButton(
                                onPressed: () => act(() => api.post('/leagues/$leagueId/team/contracts/${x['id']}/renew', {'seasons': n})),
                                child: Text(l.renewSeasons(n, money(context, n * (x['renew_one'] as num? ?? 0).toInt()))),
                              ),
                            TextButton(
                              onPressed: () async {
                                if (await confirm(context, l.releaseConfirm('${x['name']}')) && context.mounted) {
                                  await act(() => api.post('/leagues/$leagueId/team/contracts/${x['id']}/release'));
                                }
                              },
                              child: Text(
                                l.releasePlayer(money(context, (x['release'] as num? ?? 0).toInt())),
                                style: TextStyle(color: context.glm.liveText),
                              ),
                            ),
                          ],
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

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.cheerTickets,
      AsyncView(
        value: ref.watch(ticketsProvider(leagueId)),
        onRetry: () => ref.invalidate(ticketsProvider(leagueId)),
        data: (t) {
          final p = context.palette;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.cheerLead(t['boost'] as int? ?? 0, money(context, (t['price'] as num? ?? 0).toInt())),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 10),
              for (final f in (t['fixtures'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        for (final side in ['home', 'away']) ...[
                          Expanded(
                            child: Column(
                              children: [
                                ClubCrest(
                                  url: (f[side] as Map<dynamic, dynamic>?)?['crest_url'] as String?,
                                  name: '${(f[side] as Map<dynamic, dynamic>?)?['code'] ?? ''}',
                                  size: 34,
                                ),
                                Text(
                                  '${(f[side] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                                  textDirection: TextDirection.ltr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${(f['cheering'] as Map<dynamic, dynamic>?)?[side] ?? 0} 📣',
                                  style: TextStyle(color: p.textMuted, fontSize: 12),
                                ),
                                if (f['mine'] == side)
                                  Icon(Icons.check_circle_rounded, color: p.gold)
                                else if (f['mine'] == null)
                                  TextButton(
                                    onPressed: () async {
                                      await _try(
                                        context,
                                        () =>
                                            ref.read(apiProvider).post('/leagues/$leagueId/tickets', {'fixture_id': f['id'], 'side': side}),
                                      );
                                      ref.invalidate(ticketsProvider(leagueId));
                                    },
                                    child: Text(l.cheer),
                                  ),
                              ],
                            ),
                          ),
                          if (side == 'home') Text('vs', style: TextStyle(color: p.textMuted)),
                        ],
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
