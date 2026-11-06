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
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/club_data.dart';
import '../club/squad_screen.dart' show money;
import '../../core/api/api_client.dart';
import '../account/account_screens.dart' show askHoliday;
import '../club/extras_data.dart';
import '../tournaments/tournament_screens.dart' show pickWhen;
import '../home/home_data.dart';
import '../money/finance_screen.dart' show confirm;
import 'leagues_repository.dart';
import 'models.dart';
import 'widgets.dart';

/// [Sprint 16 F1, redesigned 2026-11-06] A league as a game hub: five sections in a bottom bar, the way the best manager
/// games are laid out (our own design): my club's dashboard (the next match as the hero, what needs me, the numbers),
/// the team, the matches (calendar and table), the market and money, and the rest grouped by what it is for.
class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final league = ref.watch(leagueProvider(widget.id));
    final lg = league.value;
    final hasClub = lg?.myClubId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(lg?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // [Sprint 18] The creator renames the league or moves its start until it starts.
          if (lg?.isOwner == true && lg?.locked == false)
            IconButton(tooltip: l.leagueSettings, icon: const Icon(Icons.settings_rounded), onPressed: () => _settings(context, ref, lg!)),
        ],
      ),
      bottomNavigationBar: !hasClub
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                NavigationDestination(icon: const Icon(Icons.shield_outlined), selectedIcon: const Icon(Icons.shield_rounded), label: l.navClub),
                NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups_rounded), label: l.navTeam),
                NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month_rounded), label: l.navMatches),
                NavigationDestination(icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront_rounded), label: l.navMarket),
                NavigationDestination(icon: const Icon(Icons.apps_outlined), selectedIcon: const Icon(Icons.apps_rounded), label: l.navMore),
              ],
            ),
      body: GlmBackground(
        child: AsyncView(
          value: league,
          onRetry: () => ref.invalidate(leagueProvider(widget.id)),
          data: (lg) => !hasClub
              ? _ClubTab(lg)
              : IndexedStack(index: _tab, children: [_ClubTab(lg), _TeamTab(lg), _MatchesTab(lg), _MarketTab(lg), _MoreTab(lg)]),
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
        const SizedBox(height: 8),
        _CoachesTab(lg),
      ]);
    }
    String go(String path) => '/leagues/${lg.id}/$path';
    return RefreshIndicator(
      onRefresh: () => ref.refresh(clubSummaryProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(clubSummaryProvider(lg.id)),
        onRetry: () => ref.invalidate(clubSummaryProvider(lg.id)),
        data: (s) => ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
          _NextMatchHero(s: s, leagueId: lg.id),
          const SizedBox(height: 12),
          // What needs me: the contract to sign, the matches I missed.
          if (lg.contract != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlmCard(
                gold: true,
                accent: p.gold,
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
          if (s.missed > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlmCard(
                accent: p.brand,
                onTap: () => context.push(go('missed')),
                child: Row(children: [
                  Icon(Icons.history_rounded, color: p.gold),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.missedMatches(s.missed), style: const TextStyle(fontWeight: FontWeight.w800))),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ),
          Row(children: [
            Expanded(child: StatTile(value: s.position == null ? '—' : '${s.position}/${s.teams}', label: l.tabTable, icon: Icons.leaderboard_rounded)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(value: money(context, s.cash), label: l.balance, icon: Icons.account_balance_wallet_rounded, color: p.success)),
          ]),
          if (s.goal != null) ...[
            const SizedBox(height: 10),
            GlmCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Icon(Icons.flag_rounded, color: p.gold),
                const SizedBox(width: 10),
                Expanded(child: Text('${l.board}: ${goalText(l, s.goal)}', style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
          ],
          GameHeader(l.secPlayers, icon: Icons.bolt_rounded),
          Row(children: [
            for (final (icon, label, path) in [(Icons.groups_rounded, l.squad, 'squad'), (Icons.grid_view_rounded, l.lineup, 'lineup'), (Icons.tune_rounded, l.tactics, 'tactics')])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GlmCard(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    onTap: () => context.push(go(path)),
                    child: Column(children: [
                      Icon(icon, color: p.gold, size: 26),
                      const SizedBox(height: 6),
                      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
          ]),
          for (final line in s.pending) Padding(padding: const EdgeInsets.only(top: 8), child: GlmCard(child: Text(line, style: TextStyle(color: p.textSoft)))),
        ]),
      ),
    );
  }
}

/// The next match as the screen's hero: both crests large on a pitch-green glow, the time and how long until it, the
/// line-up's state, and the way in (live when it plays, the match day panels before).
class _NextMatchHero extends StatelessWidget {
  const _NextMatchHero({required this.s, required this.leagueId});

  final ClubSummary s;
  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final live = s.matchId != null;
    final left = s.matchAt?.difference(DateTime.now());
    String? countdown;
    if (left != null && !left.isNegative) {
      countdown = left.inDays >= 1 ? '${l.days(left.inDays)} ${l.hours(left.inHours % 24)}' : left.inHours >= 1 ? l.hours(left.inHours) : l.minutes(left.inMinutes.clamp(1, 59));
    }
    Widget side(Side c) => Expanded(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06), border: Border.all(color: Colors.white.withValues(alpha: .10))),
              child: ClubCrest(url: c.crestUrl, name: c.code, size: 64),
            ),
            const SizedBox(height: 8),
            Text(c.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(p.pitchDark, p.surface, .35)!, p.surface]),
        border: Border.all(color: (live ? p.danger : p.gold).withValues(alpha: .5)),
        boxShadow: [BoxShadow(color: (live ? p.danger : p.pitch).withValues(alpha: .22), blurRadius: 30, spreadRadius: -8, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: live ? p.danger : p.gold.withValues(alpha: .16), borderRadius: BorderRadius.circular(99)),
              child: Text(live ? l.liveBadge : l.nextMatchShort, style: TextStyle(color: live ? Colors.white : context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            if (s.matchAt != null)
              Expanded(child: Text(when(context, s.matchAt!.toLocal()), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textMuted, fontSize: 12))),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            side(s.venue == 'away' ? (s.next ?? s.club) : s.club),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Column(children: [
                Text('VS', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 28, fontWeight: FontWeight.w800, color: p.gold, height: 1)),
                if (countdown != null) Text(l.countdownIn(countdown), style: TextStyle(color: p.textSoft, fontSize: 12)),
              ]),
            ),
            side(s.venue == 'away' ? s.club : (s.next ?? s.club)),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(s.lineupReady ? Icons.check_circle_rounded : Icons.error_rounded, size: 16, color: s.lineupReady ? context.glm.successText : context.glm.liveText),
            const SizedBox(width: 6),
            Text(s.lineupAuto ? l.lineupAuto : l.lineupReady, style: TextStyle(color: s.lineupReady ? context.glm.successText : context.glm.liveText, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          live
              ? GlmButton(label: l.watchLive, variant: GlmButtonVariant.brand, block: true, icon: const Icon(Icons.play_circle_fill_rounded), onPressed: () => context.push('/match/${s.matchId}'))
              : GlmButton(label: l.matchday, block: true, icon: const Icon(Icons.sports_rounded), onPressed: () => context.push('/leagues/$leagueId/matchday')),
        ]),
      ),
    );
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    void go(String path) => context.push('/leagues/${lg.id}/$path');
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      MenuSection(title: l.secPlayers, icon: Icons.groups_rounded, items: [
        MenuItem(Icons.groups_rounded, l.squad, () => go('squad'), subtitle: l.subSquad),
        MenuItem(Icons.grid_view_rounded, l.lineup, () => go('lineup'), subtitle: l.subLineup, color: p.success),
        MenuItem(Icons.tune_rounded, l.tactics, () => go('tactics'), subtitle: l.subTactics, color: p.brandLight),
      ]),
      MenuSection(title: l.secDevelop, icon: Icons.trending_up_rounded, items: [
        MenuItem(Icons.fitness_center_rounded, l.training, () => go('training'), subtitle: l.subTraining),
        MenuItem(Icons.workspace_premium_rounded, l.specialists, () => go('specialists'), subtitle: l.subSpecialists, color: p.warning),
        MenuItem(Icons.description_rounded, l.contracts, () => go('contracts'), subtitle: l.subContracts, color: p.textSoft),
      ]),
    ]);
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            for (final (icon, label, path) in [(Icons.sports_rounded, l.matchday, 'matchday'), (Icons.how_to_vote_rounded, l.predictions, 'predictions'), (Icons.bar_chart_rounded, l.stats, 'stats')])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ActionChip(avatar: Icon(icon, size: 18, color: context.palette.gold), label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onPressed: () => context.push('/leagues/${lg.id}/$path')),
                ),
              ),
          ]),
        ),
        TabBar(labelColor: context.glm.goldText, indicatorColor: context.palette.gold, tabs: [Tab(text: l.tabFixtures), Tab(text: l.tabTable)]),
        Expanded(child: TabBarView(children: [_FixturesTab(lg), _TableTab(lg)])),
      ]),
    );
  }
}

class _MarketTab extends StatelessWidget {
  const _MarketTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    void go(String path) => context.push('/leagues/${lg.id}/$path');
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      MenuSection(title: l.secDeals, icon: Icons.swap_horiz_rounded, items: [
        MenuItem(Icons.storefront_rounded, l.market, () => go('market'), subtitle: l.subMarket),
        MenuItem(Icons.travel_explore_rounded, l.scout, () => go('scout'), subtitle: l.subScout, color: p.brandLight),
      ]),
      MenuSection(title: l.secMoney, icon: Icons.payments_rounded, items: [
        MenuItem(Icons.account_balance_wallet_rounded, l.finance, () => go('finance'), subtitle: l.subFinance, color: p.success),
        MenuItem(Icons.stadium_rounded, l.stadium, () => go('stadium'), subtitle: l.subStadium),
        MenuItem(Icons.confirmation_number_rounded, l.cheerTickets, () => go('tickets'), subtitle: l.subTickets, color: p.warning),
      ]),
    ]);
  }
}

class _MoreTab extends ConsumerWidget {
  const _MoreTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    void go(String path) => context.push(path.startsWith('/') ? path : '/leagues/${lg.id}/$path');
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      MenuSection(title: l.secCompete, icon: Icons.emoji_events_rounded, items: [
        MenuItem(Icons.sports_soccer_rounded, l.friendlies, () => go('friendlies'), subtitle: l.subFriendlies, color: p.success),
        MenuItem(Icons.flag_rounded, l.quests, () => go('quests'), subtitle: l.subQuests),
        MenuItem(Icons.visibility_rounded, l.spy, () => go('spy'), subtitle: l.subSpy, color: p.danger),
        MenuItem(Icons.handshake_rounded, l.alliance, () => go('alliance'), subtitle: l.subAlliance, color: p.brandLight),
        MenuItem(Icons.emoji_events_outlined, l.tournaments, () => go('/tournaments'), subtitle: l.subTournaments, color: p.warning),
        MenuItem(Icons.military_tech_rounded, l.honours, () => go('honours'), subtitle: l.subHonours),
      ]),
      MenuSection(title: l.secCommunity, icon: Icons.forum_rounded, items: [
        MenuItem(Icons.newspaper_rounded, l.newspaper, () => go('newspaper'), subtitle: l.subNewspaper, color: p.textSoft),
        MenuItem(Icons.forum_rounded, l.groups, () => go('/groups'), subtitle: l.subGroups, color: p.brandLight),
      ]),
      GameHeader(l.secLeague, icon: Icons.groups_2_rounded),
      _CoachesTab(lg),
      const SizedBox(height: 12),
      // [Sprint 18] A holiday in this league, asked of its creator.
      GlmButton(
        label: l.holidayLeague,
        variant: GlmButtonVariant.quiet,
        icon: const Icon(Icons.beach_access_rounded),
        onPressed: () => askHoliday(context, ref, '/leagues/${lg.id}/vacation', 14),
      ),
      // [Sprint 18] Leaving the league: the team goes back to the computer (Leaving::resign), after a clear yes.
      const SizedBox(height: 20),
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
    ]);
  }
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

Future<void> _settings(BuildContext context, WidgetRef ref, League lg) async {
  final l = L.of(context);
  final name = TextEditingController(text: lg.name);
  DateTime? starts = lg.startsAt?.toLocal();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.leagueSettings, style: ctx.text.titleMedium),
          TextField(controller: name, maxLength: 60, decoration: InputDecoration(labelText: l.leagueName)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.startsOn),
            subtitle: Text(starts == null ? '—' : when(ctx, starts!)),
            onTap: () async {
              final d = await pickWhen(ctx, DateTime.now().add(const Duration(hours: 2)));
              if (d != null) set(() => starts = d);
            },
          ),
          GlmButton(label: l.save, block: true, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    ),
  );
  if (ok == true && context.mounted) {
    try {
      await ref.read(apiProvider).patch('/leagues/${lg.id}', {'name': name.text.trim(), if (starts != null) 'starts_at': starts!.toUtc().toIso8601String()});
      if (context.mounted) showGlmToast(context, l.saved);
    } on ApiError catch (e) {
      if (context.mounted) showGlmToast(context, e.message, error: true);
    }
    ref.invalidate(leagueProvider(lg.id));
  }
  name.dispose();
}

Future<void> _owner(BuildContext context, WidgetRef ref, String path, [Map<String, Object>? body]) async {
  try {
    await ref.read(apiProvider).post(path, body);
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
  }
  ref.invalidate(leagueProvider);
}

class _CoachesTab extends ConsumerWidget {
  const _CoachesTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final invite = l.inviteText(lg.name, lg.inviteUrl ?? '');
    // Inside the «more» section and the page before a team: a column, not a list of its own.
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
      // [Sprint 18] The creator answers a holiday and may remove a coach, with a reason everyone sees.
      if (lg.isOwner)
        for (final m in lg.members.where((m) => !m.isOwner))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (m.vacationRequest != null) ...[
                Text(l.vacationAsk(m.vacationRequest!.days, m.vacationRequest!.reason), style: TextStyle(color: p.textMuted, fontSize: 12)),
                TextButton(onPressed: () => _owner(context, ref, '/leagues/${lg.id}/members/${m.id}/vacation/approve'), child: Text(l.approve)),
                TextButton(onPressed: () => _owner(context, ref, '/leagues/${lg.id}/members/${m.id}/vacation/reject'), child: Text(l.reject)),
              ],
              TextButton(
                onPressed: () async {
                  final reason = TextEditingController();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: Text('${l.kick}: ${m.name}'),
                      content: TextField(controller: reason, maxLength: 200, decoration: InputDecoration(labelText: l.kickReason)),
                      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.kick))],
                    ),
                  );
                  if (ok == true && context.mounted) await _owner(context, ref, '/leagues/${lg.id}/members/${m.id}/kick', {'reason': reason.text.trim()});
                  reason.dispose();
                },
                child: Text(l.kick, style: TextStyle(color: context.glm.liveText)),
              ),
            ]),
          ),
    ]);
  }
}
