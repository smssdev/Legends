import '../../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/async_view.dart';
import '../../../ui/widgets/console.dart';
import '../../../ui/widgets/game.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_card.dart';
import '../../club/club_data.dart';
import '../leagues_repository.dart';
import '../models.dart';
import '../widgets.dart';
import 'coaches_tab.dart';
import 'daily_tasks_card.dart';
import 'hub_tiles.dart';
import 'office.dart';

class ClubTab extends ConsumerWidget {
  const ClubTab(this.lg, {super.key});

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    if (lg.myClubId == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlmCard(
            gold: true,
            child: Column(
              children: [
                Text(
                  lg.canPick
                      ? l.requestApproved
                      : lg.myRequest == 'pending'
                      ? l.requestPending
                      : lg.myRequest == 'rejected'
                      ? l.requestRejected
                      : l.pickClub,
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
                if (lg.canPick) ...[
                  const SizedBox(height: 14),
                  GlmButton(label: l.pickClub, onPressed: () => context.push('/leagues/${lg.id}/pick')),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          CoachesTab(lg),
        ],
      );
    }
    String go(String path) => '/leagues/${lg.id}/$path';
    return RefreshIndicator(
      onRefresh: () => ref.refresh(clubSummaryProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(clubSummaryProvider(lg.id)),
        onRetry: () => ref.invalidate(clubSummaryProvider(lg.id)),
        // [Sprint 46] The league's hub, the manager games' way: the next match on the stadium filling the screen,
        // then a strip of tiles for what comes next (the match's preparation, training, a friendly, the table, quests,
        // the market), each with a green «!» when it needs the coach.
        data: (s) => LayoutBuilder(
          builder: (context, box) {
            final stage = LeagueVersus(s: s, leagueId: lg.id);
            final contract = lg.contract == null
                ? null
                : GlmCard(
                    gold: true,
                    accent: p.gold,
                    child: Row(
                      children: [
                        Icon(Icons.draw_rounded, color: p.gold),
                        const SizedBox(width: 10),
                        Expanded(child: Text(goalText(l, s.goal), style: context.text.titleMedium)),
                        GlmButton(
                          label: l.sign,
                          onPressed: () async {
                            await ref.read(leaguesRepositoryProvider).signContract(lg.id);
                            ref.invalidate(leagueProvider(lg.id));
                          },
                        ),
                      ],
                    ),
                  );
            if (box.maxWidth < 560 || box.maxHeight < 300) {
              // [Sprint 47] The approved design's office on a phone: the next match, what waits for the coach, then the
              // sections as big tiles.
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ?contract,
                  SizedBox(height: 300, child: stage),
                  GameHeader(l.needsYou, icon: Icons.notifications_active_rounded),
                  _Needs(s: s, leagueId: lg.id),
                  const SizedBox(height: 14),
                  HubTiles(
                    s: s,
                    go: (path) => context.push(go(path)),
                    table: () => context.go('/leagues/${lg.id}?tab=matches'),
                    compact: true,
                    contract: lg.contract == null
                        ? null
                        : () async {
                            await ref.read(leaguesRepositoryProvider).signContract(lg.id);
                            ref.invalidate(leagueProvider(lg.id));
                          },
                  ),
                ],
              );
            }
            // [Sprint 60 F3] The office as the approved draft draws it (Office.html): the next match and its countdown first,
            // the clocks under it, the table around my place on a wide screen, and what waits for the coach beside.
            final wide = box.maxWidth >= 900;
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OfficeNextMatch(s: s, leagueId: lg.id),
                        const SizedBox(height: 8),
                        Flexible(
                          child: OfficeCounters(s: s, leagueId: lg.id),
                        ),
                      ],
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 10,
                      child: OfficeTable(s: s, leagueId: lg.id),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 10,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        ?contract,
                        if (contract != null) const SizedBox(height: 8),
                        GlmSectionTitle(
                          '${l.needsYou}${s.needs.isEmpty && s.missed == 0 ? '' : ' (${s.needs.length + (s.missed > 0 ? 1 : 0)})'}',
                        ),
                        const SizedBox(height: 6),
                        _Needs(s: s, leagueId: lg.id),
                        const SizedBox(height: 8),
                        DailyTasksCard(leagueId: lg.id),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// What needs the coach now (the server's agenda), each a line with its way in; or «all set».
class _Needs extends StatelessWidget {
  const _Needs({required this.s, required this.leagueId});

  final ClubSummary s;
  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final base = '/leagues/$leagueId';
    final rows = [
      if (s.missed > 0) (Icons.history_rounded, l.missedMatches(s.missed), '$base/missed', p.brandLight),
      for (final n in s.needs)
        switch (n.kind) {
          'window' => (Icons.sensors_rounded, l.needWindow, '/match/${n.matchId}', p.danger),
          'lineup' => (Icons.person_off_rounded, '${l.needLineup} (${n.count})', '$base/lineup', p.danger),
          'offers' => (Icons.mark_email_unread_rounded, '${l.needOffers} (${n.count})', '$base/market', p.warning),
          'requests' => (Icons.how_to_reg_rounded, '${l.needRequests} (${n.count})', '$base?tab=more', p.warning),
          'training_empty' => (Icons.fitness_center_rounded, '${l.needTrainingEmpty} (${n.count})', '$base/training', p.textSoft),
          'training_done' => (Icons.task_alt_rounded, l.needTrainingDone, '$base/training', p.success),
          _ => (Icons.info_rounded, n.kind, base, p.textSoft),
        },
    ];
    if (rows.isEmpty) {
      return GlmCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconTile(Icons.verified_rounded, color: p.success, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.allClear, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
    return GlmCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, (icon, text, path, color)) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: Colors.white.withValues(alpha: .06)),
            InkWell(
              onTap: () => context.push(path),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    IconTile(icon, color: color, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(text, style: glmText(GlmType.body, fontWeight: FontWeight.w700)),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
