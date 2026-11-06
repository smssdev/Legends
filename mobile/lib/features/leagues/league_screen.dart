import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/sounds.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/motion.dart';
import '../../ui/widgets/stadium.dart';
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
import 'shell.dart';
import 'widgets.dart';

/// [Sprint 16 F1, redesigned 2026-11-06] A league as a game hub: five sections in a bottom bar, the way the best manager
/// games are laid out (our own design): my club's dashboard (the next match as the hero, what needs me, the numbers),
/// the team, the matches (calendar and table), the market and money, and the rest grouped by what it is for.
class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key, required this.id, this.tab});

  final int id;

  /// [Sprint 45 M1] The section to open (club, team, matches, market, more), from the menu's link.
  final String? tab;

  static const tabs = ['club', 'team', 'matches', 'market', 'more'];

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  late int _tab = _of(widget.tab);

  static int _of(String? tab) => LeagueScreen.tabs.indexOf(tab ?? 'club').clamp(0, 4);

  @override
  void didUpdateWidget(LeagueScreen old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) _tab = _of(widget.tab);
  }

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
      body: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth > box.maxHeight;
        final content = GlmBackground(
          wide: true,
          child: AsyncView(
            value: league,
            onRetry: () => ref.invalidate(leagueProvider(widget.id)),
            data: (lg) => !hasClub
                ? _ClubTab(lg)
                : IndexedStack(index: _tab, children: [_ClubTab(lg), _TeamTab(lg), _MatchesTab(lg), _MarketTab(lg), _MoreTab(lg)]),
          ),
        );
        // Inside the league's menu (wide): the menu is the navigation.
        if (!hasClub || LeagueShell.of(context)) return content;
        final items = [
          (Icons.shield_outlined, Icons.shield_rounded, l.navClub),
          (Icons.groups_outlined, Icons.groups_rounded, l.navTeam),
          (Icons.calendar_month_outlined, Icons.calendar_month_rounded, l.navMatches),
          (Icons.storefront_outlined, Icons.storefront_rounded, l.navMarket),
          (Icons.apps_outlined, Icons.apps_rounded, l.navMore),
        ];
        // [2026-11-06] Landscape: the five sections in a rail at the side; upright: at the bottom.
        if (wide) {
          return Row(children: [
            NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: (i) { GameSounds.play(Sfx.tap); setState(() => _tab = i); },
              groupAlignment: 0,
              destinations: [for (final (o, f, t) in items) NavigationRailDestination(icon: Icon(o), selectedIcon: Icon(f), label: Text(t))],
            ),
            Expanded(child: content),
          ]);
        }
        return Column(children: [
          Expanded(child: content),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) { GameSounds.play(Sfx.tap); setState(() => _tab = i); },
            destinations: [for (final (o, f, t) in items) NavigationDestination(icon: Icon(o), selectedIcon: Icon(f), label: t)],
          ),
        ]);
      }),
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
        // [Sprint 45 M2] The manager's office: the next match as the hero, then the club's departments as big tiles
        // with their state, what needs me now, the table's top and the board's goal.
        data: (s) => GamePanes(startFlex: 5, endFlex: 6, start: [
          _NextMatchHero(s: s, leagueId: lg.id),
          if (lg.contract != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
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
          _MiniTable(s: s, onTap: () => context.go('/leagues/${lg.id}?tab=matches')),
        ], end: [
          _Departments(s: s, go: (path) => context.push(go(path))),
          GameHeader(l.needsYou, icon: Icons.notifications_active_rounded),
          _Needs(s: s, leagueId: lg.id),
          if (s.goal != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GlmCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  IconTile(Icons.flag_rounded, size: 34, color: p.brandLight),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${l.board}: ${goalText(l, s.goal)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

/// [Sprint 45 M2] The club's departments as the office's big tiles (the manager games' way, in our Legend Cut): each
/// with its state in a line, and a badge when it needs the coach.
class _Departments extends StatelessWidget {
  const _Departments({required this.s, required this.go});

  final ClubSummary s;
  final void Function(String path) go;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    bool needs(String kind) => s.needs.any((n) => n.kind == kind);
    final tiles = [
      (Icons.groups_rounded, l.squad, l.subSquad, 'squad', p.gold, false),
      (Icons.grid_view_rounded, l.lineup, '${s.formation ?? ''} · ${s.lineupAuto ? l.tileAuto : l.tileReady}', 'lineup', p.success, needs('lineup')),
      (Icons.tune_rounded, l.tactics, l.subTactics, 'tactics', p.brandLight, false),
      (Icons.fitness_center_rounded, l.training, l.subTraining, 'training', p.warning, needs('training_empty') || needs('training_done')),
      (Icons.storefront_rounded, l.market, l.subMarket, 'market', p.gold, needs('offers')),
      (Icons.travel_explore_rounded, l.scout, l.subScout, 'scout', p.brandLight, false),
      (Icons.account_balance_wallet_rounded, l.finance, money(context, s.cash), 'finance', p.success, false),
      (Icons.stadium_rounded, l.stadium, l.subStadium, 'stadium', p.textSoft, false),
    ];
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 520 ? 4 : box.maxWidth >= 300 ? 3 : 2;
      final w = (box.maxWidth - (cols - 1) * 8) / cols;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (i, (icon, label, sub, path, color, alert)) in tiles.indexed)
          SizedBox(
            width: w,
            child: FadeSlideIn(
              index: i,
              child: GlmCard(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                accent: color,
                onTap: () => go(path),
                child: Stack(clipBehavior: Clip.none, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    IconTile(icon, color: color, size: 40),
                    const SizedBox(height: 10),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: path == 'finance' ? TextDirection.ltr : null, textAlign: TextAlign.start,
                        style: TextStyle(color: p.textMuted, fontSize: 11.5, fontFamily: path == 'finance' ? GlmFonts.numbers : null, fontWeight: path == 'finance' ? FontWeight.w800 : null)),
                  ]),
                  if (alert) PositionedDirectional(top: -4, end: -2, child: Pulse(child: Container(width: 12, height: 12, decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle, border: Border.all(color: p.surface, width: 2))))),
                ]),
              ),
            ),
          ),
      ]);
    });
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
        child: Row(children: [
          IconTile(Icons.verified_rounded, color: p.success, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(l.allClear, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
    }
    return GlmCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (final (i, (icon, text, path, color)) in rows.indexed) ...[
          if (i > 0) Divider(height: 1, indent: 56, color: Colors.white.withValues(alpha: .06)),
          InkWell(
            onTap: () => context.push(path),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                IconTile(icon, color: color, size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                Icon(Icons.chevron_right_rounded, color: p.textMuted),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

/// The table's top and my place in it, as a small broadcast table; a tap opens the full one.
class _MiniTable extends StatelessWidget {
  const _MiniTable({required this.s, required this.onTap});

  final ClubSummary s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    if (s.top.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GameHeader(l.leagueTable, icon: Icons.leaderboard_rounded),
      GlmCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        onTap: onTap,
        child: Column(children: [
          for (final r in s.top)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              color: r.mine ? p.gold.withValues(alpha: .12) : null,
              child: Row(children: [
                Container(
                  width: 26,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: ShapeDecoration(shape: GlmCut.shape(5), color: r.position == 1 ? p.gold : p.surfaceRaised),
                  child: Text('${r.position}', textAlign: TextAlign.center, style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: r.position == 1 ? p.onGold : p.text)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, textAlign: TextAlign.start,
                    style: TextStyle(fontWeight: r.mine ? FontWeight.w800 : FontWeight.w600, color: r.mine ? context.glm.goldText : p.text))),
                Text('${r.points}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 17, color: p.text)),
              ]),
            ),
        ]),
      ),
    ]);
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
    return HeroFrame(
      edge: live ? p.danger : p.gold,
      glow: live ? p.danger : p.pitch,
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(p.pitchDark, p.surface, .35)!, p.surface]),
      child: Builder(builder: (_) => StadiumBackdrop(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: ShapeDecoration(color: live ? p.danger : p.gold.withValues(alpha: .16), shape: GlmCut.shape(GlmCut.chip + 2)),
              child: live
                  ? Pulse(child: Text(l.liveBadge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)))
                  : Text(l.nextMatchShort, style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 12)),
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
          if (s.strength != null) ...[
            const SizedBox(height: 10),
            _StrengthBar(mine: s.strength!.$1, theirs: s.strength!.$2, home: s.venue != 'away'),
          ],
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: ShapeDecoration(color: p.bgDeep.withValues(alpha: .75), shape: GlmCut.shape(GlmCut.chip + 2)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(s.lineupReady ? Icons.check_circle_rounded : Icons.error_rounded, size: 16, color: s.lineupReady ? p.success : p.danger),
                const SizedBox(width: 6),
                Text(s.lineupAuto ? l.lineupAuto : l.lineupReady, style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          live
              ? GlmButton(label: l.watchLive, variant: GlmButtonVariant.brand, block: true, icon: const Icon(Icons.play_circle_fill_rounded), onPressed: () => context.push('/match/${s.matchId}'))
              : GlmButton(label: l.matchday, block: true, icon: const Icon(Icons.sports_rounded), onPressed: () => context.push('/leagues/$leagueId/matchday')),
        ]),
      ),
      ),
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
    return GamePanes(startFlex: 1, endFlex: 1, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), start: [
      MenuSection(title: l.secPlayers, icon: Icons.groups_rounded, items: [
        MenuItem(Icons.groups_rounded, l.squad, () => go('squad'), subtitle: l.subSquad),
        MenuItem(Icons.grid_view_rounded, l.lineup, () => go('lineup'), subtitle: l.subLineup, color: p.success),
        MenuItem(Icons.tune_rounded, l.tactics, () => go('tactics'), subtitle: l.subTactics, color: p.brandLight),
      ]),
    ], end: [
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
    return GamePanes(startFlex: 1, endFlex: 1, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), start: [
      MenuSection(title: l.secDeals, icon: Icons.swap_horiz_rounded, items: [
        MenuItem(Icons.storefront_rounded, l.market, () => go('market'), subtitle: l.subMarket),
        MenuItem(Icons.travel_explore_rounded, l.scout, () => go('scout'), subtitle: l.subScout, color: p.brandLight),
      ]),
    ], end: [
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
    return GamePanes(startFlex: 1, endFlex: 1, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), start: [
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
    ], end: [
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

/// [Sprint 45 M2] Both sides' strength for the next match: two bars meeting in the middle, mine in gold.
class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.mine, required this.theirs, required this.home});

  final int mine, theirs;

  /// My club on the reading start (home) or the end (away), as the crests above.
  final bool home;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final (a, b) = home ? (mine, theirs) : (theirs, mine);
    final (ca, cb) = home ? (p.gold, p.textSoft) : (p.textSoft, p.gold);
    String n(int v) => (v / 100).toStringAsFixed(0);
    final big = TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: p.text);
    return Column(children: [
      Row(children: [
        Text(n(a), style: big),
        Expanded(child: Text(l.strengthCompare, textAlign: TextAlign.center, style: TextStyle(color: p.textSoft, fontSize: 11.5))),
        Text(n(b), style: big),
      ]),
      const SizedBox(height: 4),
      ClipPath(
        clipper: ShapeBorderClipper(shape: GlmCut.shape(4), textDirection: Directionality.of(context)),
        child: SizedBox(
          height: 8,
          child: Row(children: [
            Expanded(flex: a, child: ColoredBox(color: ca)),
            const SizedBox(width: 2),
            Expanded(flex: b == 0 && a == 0 ? 1 : b, child: ColoredBox(color: cb)),
          ]),
        ),
      ),
    ]);
  }
}
