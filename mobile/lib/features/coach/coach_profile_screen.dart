import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';

/// [Sprint 18 F1] A coach's profile (`/coaches/{id}`, Sprint 33): his record, his titles and his board objectives.
/// [Sprint 59 F1] A coach's profile through the generated model (`CoachProfile`).
final coachProfileProvider = FutureProvider.autoDispose.family<api.CoachProfile, int>(
  (ref, id) async => api.CoachProfile.fromJson(await ref.read(apiProvider).get('/coaches/$id')),
);

class CoachProfileScreen extends ConsumerWidget {
  const CoachProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
      l.coachProfile,
      AsyncView(
        value: ref.watch(coachProfileProvider(userId)),
        onRetry: () => ref.invalidate(coachProfileProvider(userId)),
        data: (j) {
          final p = context.palette;
          final coach = j.coach;
          final r = j.record;
          final titles = j.titles;
          final obj = j.objectives;
          Widget stat(String label, Object? v) => Expanded(
            child: Column(
              children: [
                Text(
                  '${v ?? 0}',
                  style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 24, fontWeight: FontWeight.w800, color: context.glm.goldText),
                ),
                Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
              ],
            ),
          );
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              GlmCard(
                gold: true,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: p.brand,
                      child: Text(
                        coach.name.characters.take(1).toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(coach.name, style: context.text.titleLarge),
                    if (coach.accountNo case final no?) Text(l.accountNumber(no), style: TextStyle(color: p.textMuted)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        stat(l.seasonsPlayed, r.seasons),
                        stat(l.played, r.played),
                        stat(l.won, r.won),
                        stat(l.drawn, r.drawn),
                        stat(l.lost, r.lost),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionTitle(l.titles),
              if (titles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l.noTitles,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted),
                  ),
                ),
              for (final t in titles)
                ListTile(
                  leading: Text(t.position == 1 ? '🏆' : '🥈', style: const TextStyle(fontSize: 22)),
                  title: Text(
                    t.club,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${t.league} · ${l.seasonN(t.season)} · ${t.competition == 'cup' ? l.cup : l.competitionLeague}'),
                ),
              const SizedBox(height: 8),
              Text(
                l.objectivesMet(obj.met, obj.total),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}
