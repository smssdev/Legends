import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/page.dart';
import '../money/finance_screen.dart' show confirm;
import 'matchday_data.dart';

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return screenPage(
      l.contracts,
      AsyncView(
        value: ref.watch(contractsProvider(leagueId)),
        onRetry: () => ref.invalidate(contractsProvider(leagueId)),
        data: (c) {
          final p = context.palette;
          final season = c.season;
          final max = c.maxSeasons;
          Future<void> act(Future<Object?> Function() a) async {
            await tryAction(context, a);
            ref.invalidate(contractsProvider(leagueId));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.contractsLead(money(context, c.wagesPerRound), money(context, c.capPerRound)),
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
              for (final x in c.players)
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
                                x.name,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.start,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              l.untilSeason(x.until),
                              style: TextStyle(color: x.until <= season ? context.glm.liveText : p.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                        Text('${x.position} · ${x.age} · ${money(context, x.wage)}', style: TextStyle(color: p.textMuted, fontSize: 12)),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (var n = 1; n <= max - (x.until - season); n++)
                              TextButton(
                                onPressed: () => act(() => api.post('/leagues/$leagueId/team/contracts/${x.id}/renew', {'seasons': n})),
                                child: Text(l.renewSeasons(n, money(context, n * x.renewOne))),
                              ),
                            TextButton(
                              onPressed: () async {
                                if (await confirm(context, l.releaseConfirm(x.name)) && context.mounted) {
                                  await act(() => api.post('/leagues/$leagueId/team/contracts/${x.id}/release'));
                                }
                              },
                              child: Text(l.releasePlayer(money(context, x.release)), style: TextStyle(color: context.glm.liveText)),
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
