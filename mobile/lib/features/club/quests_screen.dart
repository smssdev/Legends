import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;
import 'extras_data.dart';
import 'squad_screen.dart' show money;

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
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
                                    await tryAction(context, () => ref.read(extrasRepositoryProvider).claimQuest(leagueId, x.quest));
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
