import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/console.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import 'extras_data.dart';

class HonoursScreen extends ConsumerWidget {
  const HonoursScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
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
              child: GlmModelSpin(
                model: 'trophy',
                label: l.honours,
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
                            style: glmText(GlmType.headline),
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
