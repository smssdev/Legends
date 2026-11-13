import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;
import '../social/social_data.dart';
import 'quick_match_screen.dart';

class FriendliesScreen extends ConsumerWidget {
  const FriendliesScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
      l.friendlies,
      AsyncView(
        value: ref.watch(friendliesProvider(leagueId)),
        onRetry: () => ref.invalidate(friendliesProvider(leagueId)),
        data: (f) {
          final p = context.palette;
          final recent = f.recent;
          final blocked = f.blocked;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.friendlyLead(f.fitness),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              Text(
                f.firstFree ? l.friendlyFree : l.friendlyCost(f.coins),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w700),
              ),
              // [Sprint 59 F1] Why friendlies wait, in words: the screen printed the server's map as it came.
              if (blocked != null)
                Text(
                  blocked.reason == 'live'
                      ? l.friendlyBlockedLive
                      : l.friendlyBlockedSoon(blocked.until == null ? '' : when(context, DateTime.parse(blocked.until!).toLocal())),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.glm.liveText),
                ),
              const SizedBox(height: 12),
              if (recent.isNotEmpty) ...[
                SectionTitle(l.recentFriendlies),
                for (final r in recent.take(3))
                  ListTile(
                    dense: true,
                    title: Text(r.opponent.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                    trailing: Text(
                      '${r.goalsFor} - ${r.goalsAgainst}',
                      textDirection: TextDirection.ltr,
                      style: glmText(GlmType.title, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuickMatchScreen(home: f.club.name, played: r),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              for (final o in f.opponents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(10),
                    gold: o.recommended,
                    child: Row(
                      children: [
                        ClubCrest(url: o.crestUrl, name: o.code, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.name,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                [if (o.recommended) l.suggestedOpponent, if (o.playedToday) l.playedToday, ?o.coach].join(' · '),
                                style: glmText(GlmType.caption, color: p.textMuted),
                              ),
                            ],
                          ),
                        ),
                        GlmButton(
                          label: l.playFriendly,
                          onPressed: blocked != null
                              ? null
                              : () async {
                                  final r = await tryAction(context, () => ref.read(socialRepositoryProvider).playFriendly(leagueId, o.id));
                                  ref.invalidate(friendliesProvider(leagueId));
                                  if (r != null && context.mounted) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => QuickMatchScreen(home: f.club.name, played: r),
                                      ),
                                    );
                                  }
                                },
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
