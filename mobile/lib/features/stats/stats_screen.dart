import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_card.dart';
import '../account/account_data.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/page.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
      l.stats,
      AsyncView(
        value: ref.watch(statsProvider(leagueId)),
        onRetry: () => ref.invalidate(statsProvider(leagueId)),
        data: (s) {
          final p = context.palette;
          Widget list(String title, List<api.StatsPlayer> rows, int? Function(api.StatsPlayer) count, String unit) => GlmCard(
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
                          child: Text(r.player.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                        ),
                        Text('${r.club.code}  ', style: TextStyle(color: p.textMuted, fontSize: 12)),
                        Text(
                          '${count(r) ?? 0} $unit',
                          style: TextStyle(fontWeight: FontWeight.w800, color: context.glm.goldText),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
          final values = s.value;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              list(l.scorers, s.scorers, (r) => r.goals, l.goalsShort),
              const SizedBox(height: 10),
              list(l.assistsTitle, s.assists, (r) => r.assists, l.assistsShort),
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
                                '${v.position}',
                                style: TextStyle(color: p.textMuted, fontFamily: GlmFonts.numbers),
                              ),
                            ),
                            Expanded(
                              child: Text(v.club.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                            ),
                            Text(
                              money(context, v.value),
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
