import '../../../ui/tokens.g.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/async_view.dart';
import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/console.dart';
import '../../../ui/widgets/game.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_card.dart';
import '../../club/club_data.dart';
import '../../club/squad_screen.dart' show money;
import '../leagues_repository.dart';
import '../models.dart';
import '../widgets.dart';
import 'coaches_tab.dart';
import 'daily_tasks_card.dart';
import 'hub_tiles.dart';

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
            final tiles = HubTiles(
              s: s,
              go: (path) => context.push(go(path)),
              table: () => context.go('/leagues/${lg.id}?tab=matches'),
              contract: lg.contract == null
                  ? null
                  : () async {
                      await ref.read(leaguesRepositoryProvider).signContract(lg.id);
                      ref.invalidate(leagueProvider(lg.id));
                    },
            );
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
            // [Sprint 50 M9] The console's office: three columns at a glance, no scrolling: the club and the coach, the
            // next match on its stadium, and the operations (today's tasks, then what waits for the coach). The sections
            // are the dock's; the tiles stay on a short screen only.
            if (box.maxWidth >= 760) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 26,
                      child: _ClubColumn(s: s, leagueId: lg.id),
                    ),
                    const SizedBox(width: 8),
                    Expanded(flex: 46, child: stage),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 28,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          ?contract,
                          if (contract != null) const SizedBox(height: 8),
                          DailyTasksCard(leagueId: lg.id),
                          const SizedBox(height: 8),
                          GlmSectionTitle(l.needsYou),
                          const SizedBox(height: 6),
                          _Needs(s: s, leagueId: lg.id),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Expanded(child: stage),
                SizedBox(height: math.min(250, box.maxHeight * .52), child: tiles),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// [Sprint 50 M9] The office's first column: the club's crest and its coach's place, the treasury, the way to set the
/// team, and the table's top.
class _ClubColumn extends StatelessWidget {
  const _ClubColumn({required this.s, required this.leagueId});

  final ClubSummary s;
  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return GlmCard(
      padding: const EdgeInsets.all(10),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GlmSectionTitle(l.clubAndCoach),
          const SizedBox(height: 8),
          Row(
            children: [
              ClubCrest(url: s.club.crestUrl, name: s.club.code, size: 42),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.club.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: glmText(GlmType.body, fontWeight: FontWeight.w800),
                    ),
                    if (s.position != null && s.teams != null)
                      Text(l.position(s.position!, s.teams!), style: glmText(GlmType.caption, color: p.goldLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: p.surfaceSunk, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Text(l.treasury, style: glmText(GlmType.caption, color: p.textMuted)),
                const Spacer(),
                Text(
                  money(context, s.cash),
                  textDirection: TextDirection.ltr,
                  style: glmText(GlmType.bodyLg, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: p.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GlmButton(
            label: l.setTeam,
            variant: GlmButtonVariant.brand,
            block: true,
            onPressed: () => context.go('/leagues/$leagueId/lineup'),
          ),
          if (s.top.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(l.leagueTable, style: glmText(GlmType.caption, color: p.textMuted)),
            const SizedBox(height: 4),
            for (final r in s.top)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: r.mine ? p.gold.withValues(alpha: .14) : null, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${r.position}',
                        style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: glmText(GlmType.caption, color: r.mine ? p.goldLight : p.text),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${r.points}',
                      style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ],
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
