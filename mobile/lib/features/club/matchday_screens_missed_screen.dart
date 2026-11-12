part of 'matchday_screens.dart';

/// [Sprint 20 B3] The matches played while the coach was away: each result, its scorers, the man of the match, the
/// coins and what changed in the squad; a tap opens the report, and «seen» clears them.
class MissedScreen extends ConsumerWidget {
  const MissedScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return Scaffold(
      appBar: GameBar(
        title: Text(l.missedTitle),
        actions: [
          TextButton(
            onPressed: () async {
              await _try(context, () => ref.read(apiProvider).post('/leagues/$leagueId/team/missed/seen'));
              ref.invalidate(missedProvider(leagueId));
              if (context.mounted) Navigator.of(context).maybePop();
            },
            child: Text(l.markSeen),
          ),
        ],
      ),
      body: GlmBackground(
        child: AsyncView(
          value: ref.watch(missedProvider(leagueId)),
          onRetry: () => ref.invalidate(missedProvider(leagueId)),
          data: (list) => ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final m in list.cast<Map<dynamic, dynamic>>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    gold: m['result'] == 1,
                    onTap: () => GoRouter.of(context).push('/match/${m['match_id']}/report?coach=true'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${(m['home'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${m['home_goals']} - ${m['away_goals']}',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontFamily: GlmFonts.numbers, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            Expanded(
                              child: Text(
                                '${(m['away'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        for (final g in (m['goals'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>())
                          Text(
                            "⚽ ${g['minute']}' ${g['scorer'] ?? ''}",
                            textDirection: TextDirection.ltr,
                            textAlign: g['side'] == 'home' ? TextAlign.left : TextAlign.right,
                            style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                          ),
                        if (m['man_of_the_match'] is Map<dynamic, dynamic>)
                          Text('${l.manOfMatch}: ${(m['man_of_the_match'] as Map<dynamic, dynamic>)['name'] ?? ''}'),
                        if ((m['coins'] as int? ?? 0) != 0)
                          Text(l.coinsWord(m['coins'] as int), style: TextStyle(color: context.glm.goldText)),
                        for (final c in (m['changes'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>())
                          Text(
                            '${c['kind'] == 'injury' ? '🩹 ${l.injured}' : '🟥 ${l.sentOff}'}: ${c['player'] ?? ''}',
                            style: TextStyle(color: context.glm.liveText, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
