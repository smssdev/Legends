import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import '../leagues/shell.dart';
import 'matchday_data.dart';

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
              await tryAction(context, () => ref.read(apiProvider).post('/leagues/$leagueId/team/missed/seen'));
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
              for (final m in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    gold: m.result == 1,
                    onTap: () => GoRouter.of(context).push('/match/${m.matchId}/report?coach=true'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.home.name,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${m.homeGoals} - ${m.awayGoals}',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontFamily: GlmFonts.numbers, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            Expanded(
                              child: Text(
                                m.away.name,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        for (final g in m.goals)
                          Text(
                            "⚽ ${g.minute}' ${g.scorer ?? ''}",
                            textDirection: TextDirection.ltr,
                            textAlign: g.side == 'home' ? TextAlign.left : TextAlign.right,
                            style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                          ),
                        if (m.manOfTheMatch case final motm?) Text('${l.manOfMatch}: ${motm.name ?? ''}'),
                        if (m.coins != 0) Text(l.coinsWord(m.coins), style: TextStyle(color: context.glm.goldText)),
                        for (final c in m.changes)
                          Text(
                            '${c.kind == 'injury' ? '🩹 ${l.injured}' : '🟥 ${l.sentOff}'}: ${c.player ?? ''}',
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
