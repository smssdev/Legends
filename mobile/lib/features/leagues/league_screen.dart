import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/club_data.dart';
import '../club/extras_data.dart';
import '../home/home_data.dart';
import '../money/finance_screen.dart' show confirm;
import 'leagues_repository.dart';
import 'models.dart';
import 'widgets.dart';

/// [Sprint 16 F1] A league: my club's board, the table, the matches (league and cup by round), and the coaches with the
/// creator's join requests and the invite to share. Before a team: the way to take one, or the request's state.
class LeagueScreen extends ConsumerWidget {
  const LeagueScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final league = ref.watch(leagueProvider(id));
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(league.value?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, labelColor: context.glm.goldText, indicatorColor: context.palette.gold,
              tabs: [Tab(text: l.tabClub), Tab(text: l.tabTable), Tab(text: l.tabFixtures), Tab(text: l.tabCoaches)]),
        ),
        body: GlmBackground(
          child: AsyncView(
            value: league,
            onRetry: () => ref.invalidate(leagueProvider(id)),
            data: (lg) => TabBarView(children: [_ClubTab(lg), _TableTab(lg), _FixturesTab(lg), _CoachesTab(lg)]),
          ),
        ),
      ),
    );
  }
}

class _ClubTab extends ConsumerWidget {
  const _ClubTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    if (lg.myClubId == null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        GlmCard(
          gold: true,
          child: Column(children: [
            Text(lg.canPick ? l.requestApproved : lg.myRequest == 'pending' ? l.requestPending : lg.myRequest == 'rejected' ? l.requestRejected : l.pickClub,
                textAlign: TextAlign.center, style: context.text.titleMedium),
            if (lg.canPick) ...[
              const SizedBox(height: 14),
              GlmButton(label: l.pickClub, onPressed: () => context.push('/leagues/${lg.id}/pick')),
            ],
          ]),
        ),
      ]);
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(clubSummaryProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(clubSummaryProvider(lg.id)),
        onRetry: () => ref.invalidate(clubSummaryProvider(lg.id)),
        data: (s) => ListView(padding: const EdgeInsets.all(16), children: [
          if (lg.contract != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlmCard(
                gold: true,
                child: Row(children: [
                  Icon(Icons.draw_rounded, color: p.gold),
                  const SizedBox(width: 10),
                  Expanded(child: Text(goalText(l, s.goal), style: context.text.titleMedium)),
                  GlmButton(label: l.sign, onPressed: () async {
                    await ref.read(leaguesRepositoryProvider).signContract(lg.id);
                    ref.invalidate(leagueProvider(lg.id));
                  }),
                ]),
              ),
            ),
          GlmCard(
            gold: true,
            child: Column(children: [
              Row(children: [
                Text(l.nextMatchShort, style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                if (s.matchAt != null)
                  Expanded(child: Text(when(context, s.matchAt!), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textMuted, fontSize: 13))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(children: [ClubCrest(url: s.club.crestUrl, name: s.club.code, size: 56), const SizedBox(height: 6), Text(s.club.name, textAlign: TextAlign.center, style: context.text.titleSmall)])),
                Text(s.venue == 'away' ? l.away : l.home, style: TextStyle(color: p.textMuted, fontSize: 12)),
                Expanded(child: Column(children: [ClubCrest(url: s.next?.crestUrl, name: s.next?.code ?? '', size: 56), const SizedBox(height: 6), Text(s.next?.name ?? '—', textAlign: TextAlign.center, style: context.text.titleSmall)])),
              ]),
              const SizedBox(height: 12),
              Text(s.lineupAuto ? l.lineupAuto : l.lineupReady, style: TextStyle(color: s.lineupReady ? context.glm.successText : context.glm.liveText, fontWeight: FontWeight.w700)),
              if (s.matchId != null) ...[
                const SizedBox(height: 12),
                GlmButton(label: l.watchLive, variant: GlmButtonVariant.brand, block: true, icon: const Icon(Icons.play_circle_fill_rounded), onPressed: () => context.push('/match/${s.matchId}')),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          // [Sprint 17] My team's screens.
          // [Sprint 18] And the club's other screens, three to a row.
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.25,
            children: [
              for (final (icon, label, path) in [
                (Icons.sports_rounded, l.matchday, 'matchday'),
                (Icons.groups_rounded, l.squad, 'squad'), (Icons.grid_view_rounded, l.lineup, 'lineup'), (Icons.tune_rounded, l.tactics, 'tactics'),
                (Icons.description_rounded, l.contracts, 'contracts'), (Icons.confirmation_number_rounded, l.cheerTickets, 'tickets'),
                (Icons.swap_horiz_rounded, l.market, 'market'), (Icons.travel_explore_rounded, l.scout, 'scout'),
                (Icons.account_balance_wallet_rounded, l.finance, 'finance'), (Icons.stadium_rounded, l.stadium, 'stadium'),
                (Icons.fitness_center_rounded, l.training, 'training'), (Icons.workspace_premium_rounded, l.specialists, 'specialists'),
                (Icons.visibility_rounded, l.spy, 'spy'), (Icons.flag_rounded, l.quests, 'quests'), (Icons.emoji_events_rounded, l.honours, 'honours'),
                (Icons.sports_soccer_rounded, l.friendlies, 'friendlies'), (Icons.how_to_vote_rounded, l.predictions, 'predictions'),
                (Icons.newspaper_rounded, l.newspaper, 'newspaper'), (Icons.forum_rounded, l.groups, '/groups'), (Icons.leaderboard_rounded, l.stats, 'stats'), (Icons.handshake_rounded, l.alliance, 'alliance'), (Icons.emoji_events_outlined, l.tournaments, '/tournaments'),
              ])
                GlmCard(
                  padding: const EdgeInsets.all(8),
                  onTap: () => context.push(path.startsWith('/') ? path : '/leagues/${lg.id}/$path'),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, color: p.gold),
                    const SizedBox(height: 6),
                    Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Stat(label: l.tabTable, value: s.position == null ? '—' : '${s.position}/${s.teams}')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(label: l.coins, value: '${s.coins}')),
          ]),
          if (s.goal != null) ...[const SizedBox(height: 12), GlmCard(child: Row(children: [Icon(Icons.flag_rounded, color: p.gold), const SizedBox(width: 10), Expanded(child: Text('${l.board}: ${goalText(l, s.goal)}'))]))],
          for (final line in s.pending) Padding(padding: const EdgeInsets.only(top: 8), child: GlmCard(child: Text(line, style: TextStyle(color: p.textSoft)))),
          // [Sprint 18] Leaving the league: the team goes back to the computer (Leaving::resign), after a clear yes.
          const SizedBox(height: 28),
          GlmButton(
            label: l.resign,
            variant: GlmButtonVariant.danger,
            onPressed: () async {
              if (!await confirm(context, l.resignConfirm) || !context.mounted) return;
              try {
                await ref.read(extrasRepositoryProvider).resign(lg.id);
                ref.invalidate(homeProvider);
                ref.invalidate(myLeaguesProvider);
                if (context.mounted) context.go('/');
              } on ApiError catch (e) {
                if (context.mounted) showGlmToast(context, e.message, error: true);
              }
            },
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) => GlmCard(
        child: Column(children: [
          Text(value, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 28, fontWeight: FontWeight.w800, color: context.glm.goldText)),
          Text(label, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
        ]),
      );
}

class _TableTab extends ConsumerWidget {
  const _TableTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    TextStyle num([bool strong = false]) => TextStyle(fontFamily: GlmFonts.numbers, fontSize: 16, fontWeight: strong ? FontWeight.w800 : FontWeight.w600, color: strong ? p.text : p.textSoft);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(standingsProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(standingsProvider(lg.id)),
        onRetry: () => ref.invalidate(standingsProvider(lg.id)),
        data: (rows) => ListView(padding: const EdgeInsets.all(12), children: [
          for (final r in rows)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: r.id == lg.myClubId ? p.gold.withValues(alpha: .14) : p.surface,
                borderRadius: BorderRadius.circular(GlmSize.radiusLg),
                border: Border.all(color: r.id == lg.myClubId ? p.gold.withValues(alpha: .5) : p.surfaceRaised),
              ),
              child: Row(children: [
                SizedBox(width: 26, child: Text('${r.position}', style: num(true))),
                ClubCrest(url: r.crestUrl, name: r.code, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (r.coach != null) Text(r.coach!, style: TextStyle(color: p.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                SizedBox(width: 28, child: Text('${r.played}', style: num(), textAlign: TextAlign.center)),
                SizedBox(width: 36, child: Text('${r.gd > 0 ? '+' : ''}${r.gd}', style: num(), textAlign: TextAlign.center, textDirection: TextDirection.ltr)),
                SizedBox(width: 34, child: Text('${r.points}', style: num(true), textAlign: TextAlign.center)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _FixturesTab extends ConsumerWidget {
  const _FixturesTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(fixturesProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(fixturesProvider(lg.id)),
        onRetry: () => ref.invalidate(fixturesProvider(lg.id)),
        data: (all) {
          final shown = all.where((f) => !f.isBye).toList();
          if (shown.isEmpty) return ListView(children: [Padding(padding: const EdgeInsets.all(32), child: Text(l.noMatches, textAlign: TextAlign.center))]);
          // Grouped by round (league) or stage (cup), in their order.
          final groups = <String, List<Fixture>>{};
          for (final f in shown) {
            groups.putIfAbsent(f.competition == 'cup' ? '${l.cup} · ${f.stage ?? ''}' : l.round(f.round ?? 0), () => []).add(f);
          }
          final firstOpen = groups.keys.toList().indexWhere((k) => groups[k]!.any((f) => !f.finished));
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final (i, k) in groups.keys.indexed)
              ExpansionTile(
                initiallyExpanded: i == firstOpen || (firstOpen == -1 && i == groups.length - 1),
                title: Text(k, style: context.text.titleMedium),
                subtitle: groups[k]!.first.at == null ? null : Text(when(context, groups[k]!.first.at!), style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
                children: [for (final f in groups[k]!) FixtureTile(f, mine: lg.myClubId)],
              ),
          ]);
        },
      ),
    );
  }
}

class _CoachesTab extends ConsumerWidget {
  const _CoachesTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final invite = l.inviteText(lg.name, lg.inviteUrl ?? '');
    return ListView(padding: const EdgeInsets.all(16), children: [
      GlmCard(
        gold: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.invite, style: context.text.titleMedium),
          const SizedBox(height: 8),
          SelectableText(lg.code, textAlign: TextAlign.center, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 30, letterSpacing: 4, fontWeight: FontWeight.w800, color: context.glm.goldText)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GlmButton(label: l.share, icon: const Icon(Icons.share_rounded), onPressed: () => SharePlus.instance.share(ShareParams(text: invite)))),
            const SizedBox(width: 10),
            Expanded(child: GlmButton(label: l.code, variant: GlmButtonVariant.quiet, icon: const Icon(Icons.copy_rounded), onPressed: () {
              Clipboard.setData(ClipboardData(text: lg.code));
              showGlmToast(context, l.copied);
            })),
          ]),
        ]),
      ),
      if (lg.isOwner) ...[
        SectionTitle(l.requests),
        AsyncView(
          value: ref.watch(requestsProvider(lg.id)),
          data: (reqs) => Column(children: [
            for (final r in reqs.where((r) => r.status == 'pending'))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlmCard(
                  child: Row(children: [
                    Expanded(child: Text('${r.name}${r.username == null ? '' : ' · @${r.username}'}', style: const TextStyle(fontWeight: FontWeight.w700))),
                    IconButton(tooltip: l.approve, icon: Icon(Icons.check_circle_rounded, color: p.success), onPressed: () async {
                      await ref.read(leaguesRepositoryProvider).decide(lg.id, r.id, true);
                      ref..invalidate(requestsProvider(lg.id))..invalidate(leagueProvider(lg.id));
                    }),
                    IconButton(tooltip: l.reject, icon: Icon(Icons.cancel_rounded, color: p.live), onPressed: () async {
                      await ref.read(leaguesRepositoryProvider).decide(lg.id, r.id, false);
                      ref.invalidate(requestsProvider(lg.id));
                    }),
                  ]),
                ),
              ),
          ]),
        ),
      ],
      SectionTitle('${l.tabCoaches} · ${lg.members.length}'),
      for (final m in lg.members)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: p.brand, child: Text(m.name.characters.take(1).toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text([if (m.club != null) m.club!, if (m.isOwner) l.creator, if (m.onHoliday) l.onHoliday].join(' · ')),
          trailing: m.userId == null ? null : const Icon(Icons.chevron_right_rounded),
          onTap: m.userId == null ? null : () => context.push('/coaches/${m.userId}'),
        ),
    ]);
  }
}
