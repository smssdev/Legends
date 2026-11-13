import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/action_bar.dart';
import '../../ui/widgets/glm_button.dart';
import '../leagues/page.dart';
import 'tournaments_data.dart';

class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
      l.tournaments,
      AsyncView(
        value: ref.watch(tournamentsProvider),
        onRetry: () => ref.invalidate(tournamentsProvider),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noTournaments))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final t in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlmCard(
                        onTap: () => context.push('/tournaments/${t.id}'),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events_rounded, color: context.palette.gold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(
                                    '${templateName(l, t.template ?? '')} · ${l.teamsCount(t.teamCount)}',
                                    style: glmText(GlmType.caption, color: context.palette.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
      bar: GlmActionBar(
        actions: const [],
        main: GlmButton(label: l.newTournament, icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/tournaments/new')),
      ),
    );
  }
}
