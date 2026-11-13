import '../../ui/widgets/glm_icon.dart';
import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/page.dart';
import 'matchday_data.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
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
                l.cheerLead(t.boost, money(context, t.price)),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 10),
              for (final f in t.fixtures)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        for (final (side, club, cheering) in [
                          ('home', (name: f.home.name, code: f.home.code, crest: f.home.crestUrl), f.cheering.home),
                          ('away', (name: f.away.name, code: f.away.code, crest: f.away.crestUrl), f.cheering.away),
                        ]) ...[
                          Expanded(
                            child: Column(
                              children: [
                                ClubCrest(url: club.crest, name: club.code, size: 34),
                                Text(club.name, textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$cheering ', style: glmText(GlmType.caption, color: p.textMuted)),
                                    GlmIcon(GlmIcons.megaphone, size: 14, color: p.textMuted),
                                  ],
                                ),
                                if (f.mine == side)
                                  Icon(Icons.check_circle_rounded, color: p.gold)
                                else if (f.mine == null)
                                  TextButton(
                                    onPressed: () async {
                                      await tryAction(
                                        context,
                                        () => ref.read(apiProvider).post('/leagues/$leagueId/tickets', {'fixture_id': f.id, 'side': side}),
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
