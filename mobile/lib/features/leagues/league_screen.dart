import 'dart:math' as math;
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
import '../../ui/widgets/game_icons.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/motion.dart';
import '../../ui/widgets/stadium.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/club_data.dart';
import '../club/squad_screen.dart' show money;
import '../console/console_data.dart';
import '../../ui/widgets/console.dart';
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
      appBar: GameBar(
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
        // [Sprint 46] The league's hub, the manager games' way: the next match on the stadium filling the screen,
        // then a strip of tiles for what comes next (the match's preparation, training, a friendly, the table, quests,
        // the market), each with a green «!» when it needs the coach.
        data: (s) => LayoutBuilder(builder: (context, box) {
          final stage = _Versus(s: s, leagueId: lg.id);
          final tiles = _HubTiles(s: s, go: (path) => context.push(go(path)), table: () => context.go('/leagues/${lg.id}?tab=matches'),
              contract: lg.contract == null ? null : () async {
                await ref.read(leaguesRepositoryProvider).signContract(lg.id);
                ref.invalidate(leagueProvider(lg.id));
              });
          final contract = lg.contract == null
              ? null
              : GlmCard(
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
                );
          if (box.maxWidth < 560 || box.maxHeight < 300) {
            // [Sprint 47] The approved design's office on a phone: the next match, what waits for the coach, then the
            // sections as big tiles.
            return ListView(padding: const EdgeInsets.all(12), children: [
              ?contract,
              SizedBox(height: 300, child: stage),
              GameHeader(l.needsYou, icon: Icons.notifications_active_rounded),
              _Needs(s: s, leagueId: lg.id),
              const SizedBox(height: 14),
              _HubTiles(s: s, go: (path) => context.push(go(path)), table: () => context.go('/leagues/${lg.id}?tab=matches'), compact: true,
                  contract: lg.contract == null ? null : () async {
                    await ref.read(leaguesRepositoryProvider).signContract(lg.id);
                    ref.invalidate(leagueProvider(lg.id));
                  }),
            ]);
          }
          // [Sprint 50 M9] The console's office: three columns at a glance, no scrolling: the club and the coach, the
          // next match on its stadium, and the operations (today's tasks, then what waits for the coach). The sections
          // are the dock's; the tiles stay on a short screen only.
          if (box.maxWidth >= 760) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(flex: 26, child: _ClubColumn(s: s, leagueId: lg.id)),
                const SizedBox(width: 8),
                Expanded(flex: 46, child: stage),
                const SizedBox(width: 8),
                Expanded(flex: 28, child: ListView(padding: EdgeInsets.zero, children: [
                  ?contract,
                  if (contract != null) const SizedBox(height: 8),
                  DailyTasksCard(leagueId: lg.id),
                  const SizedBox(height: 8),
                  GlmSectionTitle(l.needsYou),
                  const SizedBox(height: 6),
                  _Needs(s: s, leagueId: lg.id),
                ])),
              ]),
            );
          }
          return Column(children: [
            Expanded(child: stage),
            SizedBox(height: math.min(250, box.maxHeight * .52), child: tiles),
          ]);
        }),
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
      child: ListView(padding: EdgeInsets.zero, children: [
        GlmSectionTitle(l.clubAndCoach),
        const SizedBox(height: 8),
        Row(children: [
          ClubCrest(url: s.club.crestUrl, name: s.club.code, size: 42),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.club.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              if (s.position != null && s.teams != null) Text(l.position(s.position!, s.teams!), style: TextStyle(color: p.goldLight, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: p.surfaceSunk, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Text(l.treasury, style: TextStyle(color: p.textMuted, fontSize: 12)),
            const Spacer(),
            Text(money(context, s.cash), textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 16, color: p.success)),
          ]),
        ),
        const SizedBox(height: 8),
        GlmButton(label: l.setTeam, variant: GlmButtonVariant.brand, block: true, onPressed: () => context.go('/leagues/$leagueId/lineup')),
        if (s.top.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(l.leagueTable, style: TextStyle(color: p.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          for (final r in s.top)
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: r.mine ? p.gold.withValues(alpha: .14) : null, borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                SizedBox(width: 20, child: Text('${r.position}', style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700))),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 12, color: r.mine ? p.goldLight : p.text)),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${r.points}', style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700)),
              ]),
            ),
        ],
      ]),
    );
  }
}

/// [Sprint 50 M10] Today's tasks (the server's): each done one claims its coins, and the bar fills as they are done.
class DailyTasksCard extends ConsumerWidget {
  const DailyTasksCard({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final tasks = ref.watch(dailyTasksProvider(leagueId)).value;
    if (tasks == null) return const SizedBox.shrink();
    String name(String t) => switch (t) { 'lineup' => l.taskLineup, 'friendly' => l.taskFriendly, 'training' => l.taskTraining, _ => l.taskChat };
    return GlmCard(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlmSectionTitle(l.dailyTasks, trailing: Text('${tasks.done}/${tasks.total}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: p.goldLight))),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: tasks.total == 0 ? 0 : tasks.done / tasks.total, minHeight: 5, color: p.gold, backgroundColor: p.surfaceRaised),
        ),
        const SizedBox(height: 4),
        for (final t in tasks.tasks)
          SizedBox(
            height: 44,
            child: Row(children: [
              Icon(t.complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: t.complete ? p.success : p.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text(name(t.task), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              if (t.claimed)
                Icon(Icons.done_all_rounded, size: 18, color: context.glm.successText)
              else if (t.complete)
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: p.gold, foregroundColor: p.onGold, minimumSize: const Size(64, 34), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    try {
                      await ref.read(consoleRepositoryProvider).claimTask(leagueId, t.task);
                    } on ApiError catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                    ref.invalidate(dailyTasksProvider(leagueId));
                    ref.invalidate(clubSummaryProvider(leagueId));
                  },
                  child: Text('+${t.coins}', style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800)),
                )
              else
                Text('+${t.coins}', style: TextStyle(fontFamily: GlmFonts.numbers, color: p.textMuted)),
            ]),
          ),
      ]),
    );
  }
}

/// [Sprint 46] The next match on the stadium: both clubs' crests large with their strength in a lit ring, the round, the
/// countdown, a great «VS», where it is played, and the way in (live when it plays, the match day before).
class _Versus extends StatelessWidget {
  const _Versus({required this.s, required this.leagueId});

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
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final (d, h, m) = (left.inDays, left.inHours % 24, left.inMinutes % 60);
      countdown = ar ? '${d > 0 ? '$dي ' : ''}$hس $mد' : '${d > 0 ? '${d}d ' : ''}${h}h ${m}m';
    }
    final home = s.venue != 'away';
    final (homeSide, awaySide) = home ? (s.club, s.next ?? s.club) : (s.next ?? s.club, s.club);
    final (hs, as_) = s.strength == null ? (null, null) : home ? (s.strength!.$1, s.strength!.$2) : (s.strength!.$2, s.strength!.$1);
    Widget team(Side c, int? strength, bool mine) => Expanded(
          child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // [Sprint 46, the polish] The crest on a soft halo of light, as under the floodlights.
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: (mine ? context.palette.gold : GlmStage.accent).withValues(alpha: .35), blurRadius: 30, spreadRadius: 4)]),
                child: ClubCrest(url: c.crestUrl, name: c.code, size: 84),
              ),
              if (strength != null) ...[const SizedBox(width: 10), _Ring(value: strength ~/ 100, mine: mine)],
            ]),
            const SizedBox(height: 6),
            Text(c.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 28, color: Colors.white, height: 1.05,
                    shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 6)])),
          ])),
        );
    return StadiumBackdrop(
      tint: live ? p.live : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          team(homeSide, hs, home),
          SizedBox(
            width: 190,
            child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: ShapeDecoration(shape: GlmCut.shape(10, side: BorderSide(color: Colors.white.withValues(alpha: .15))), color: GlmStage.card.withValues(alpha: .9)),
                child: Text(s.round == null ? l.nextMatchShort : l.round(s.round!), style: TextStyle(color: p.goldLight, fontWeight: FontWeight.w800, fontSize: 17)),
              ),
              const SizedBox(height: 6),
              if (live)
                Pulse(child: Text(l.liveBadge, style: TextStyle(color: p.danger, fontWeight: FontWeight.w800, fontSize: 18)))
              else if (countdown != null)
                Text(countdown, style: const TextStyle(fontFamily: GlmFonts.numbers, fontFamilyFallback: [GlmFonts.body], fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white)),
              Pulse(min: .7, child: Text('VS', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 60, height: 1,
                  foreground: Paint()..shader = LinearGradient(colors: [p.goldLight, p.gold, p.goldDark]).createShader(const Rect.fromLTWH(0, 0, 80, 60)),
                  shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 8)]))),
              Text(home ? l.homeAway : l.awayGame, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 6),
              live
                  ? GlmButton(label: l.watchLive, variant: GlmButtonVariant.brand, icon: const Icon(Icons.play_circle_fill_rounded), onPressed: () => context.push('/match/${s.matchId}'))
                  : GlmButton(label: l.matchday, icon: const Icon(Icons.sports_rounded), onPressed: () => context.push('/leagues/$leagueId/matchday')),
            ])),
          ),
          team(awaySide, as_, !home),
        ]),
      ),
    );
  }
}

/// A club's strength as a number in a lit ring: mine in gold, theirs in blue.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.mine});

  final int value;
  final bool mine;

  @override
  Widget build(BuildContext context) => ArcGauge(value: value, size: 68, color: mine ? context.palette.gold : GlmStage.accent);
}

/// The hub's strip of tiles under the match, scrolling across when it does not fit.
class _HubTiles extends StatelessWidget {
  const _HubTiles({required this.s, required this.go, required this.table, this.contract, this.compact = false});

  final ClubSummary s;

  /// A phone held upright: two rows of four tiles.
  final bool compact;
  final void Function(String path) go;
  final VoidCallback table;

  /// The contract to sign (the board's goal), first in the strip while it waits.
  final VoidCallback? contract;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    bool needs(String kind) => s.needs.any((n) => n.kind == kind);
    final missing = needs('lineup');
    final prep = missing ? .35 : s.lineupAuto ? .7 : 1.0;
    DateTime? timer(String kind) => s.timers.where((t) => t.kind == kind).firstOrNull?.at;
    String left(DateTime? at) {
      if (at == null) return '';
      final d = at.difference(DateTime.now());
      if (d.isNegative) return '';
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      return d.inDays > 0 ? (ar ? '${d.inDays}ي' : '${d.inDays}d') : (ar ? '${d.inHours}س ${d.inMinutes % 60}د' : '${d.inHours}h ${d.inMinutes % 60}m');
    }

    final table = _HubTile(
      onTap: this.table,
      icon: GameGlyph.table,
      title: l.leagueTable,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final r in s.top.take(3))
          Container(
            color: r.mine ? Colors.white.withValues(alpha: .08) : null,
            child: Row(children: [
              SizedBox(width: 22, child: Text('${r.position}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: r.mine ? p.goldLight : Colors.white70))),
              Expanded(child: Text(r.name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start,
                  style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 14, height: 1.2, color: r.mine ? p.goldLight : Colors.white))),
              const SizedBox(width: 8),
              Text('${r.points}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: r.mine ? p.goldLight : Colors.white)),
            ]),
          ),
      ]),
    );
    // [Sprint 46, the owner's screenshots] Two rows under the match, filling the width as the manager games do: the
    // quick friendly, the match's preparation, training's clock and the form; then the quests (or the contract), the
    // market and the table.
    // [Sprint 47] On a phone, the approved design's office: four big tiles a row, each its icon over its name.
    if (compact) {
      final tiles = <Widget>[
        _HubTile(upright: true, alert: missing, onTap: () => go('lineup'), icon: GameGlyph.lineup, title: l.lineup,
            child: SizedBox(width: 56, child: _Progress(value: prep, color: missing ? p.danger : prep < 1 ? p.gold : p.success))),
        _HubTile(upright: true, onTap: () => go('tactics'), icon: GameGlyph.tactics, title: l.tactics),
        _HubTile(upright: true, alert: needs('training_empty') || needs('training_done'), onTap: () => go('training'), icon: GameGlyph.training,
            title: left(timer('training')).isEmpty ? l.training : left(timer('training'))),
        _HubTile(upright: true, onTap: () => go('friendlies'), icon: GameGlyph.quick, title: l.friendlies),
        contract != null
            ? _HubTile(upright: true, gold: true, alert: true, onTap: contract!, icon: GameGlyph.contracts, title: l.sign)
            : _HubTile(upright: true, gold: true, onTap: () => go('quests'), icon: GameGlyph.quests, title: l.quests),
        _HubTile(upright: true, alert: needs('offers'), onTap: () => go('market'), icon: GameGlyph.transfers, title: l.market),
        _HubTile(upright: true, onTap: this.table, icon: GameGlyph.table, title: l.leagueTable),
        _HubTile(upright: true, onTap: () => go('stats'), icon: GameGlyph.honours, title: l.form, child: _Form(s.form)),
      ];
      return Column(children: [
        for (final r in [0, 4])
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
            child: SizedBox(
              height: 92,
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = r; i < r + 4; i++) ...[if (i > r) const SizedBox(width: 8), Expanded(child: FadeSlideIn(index: i, child: tiles[i]))],
              ]),
            ),
          ),
      ]);
    }
    Widget row(List<(int, Widget)> xs) => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, (flex, w)) in xs.indexed) ...[if (i > 0) const SizedBox(width: 10), Expanded(flex: flex, child: FadeSlideIn(index: i, child: w))],
        ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(children: [
        Expanded(
          child: row([
            (5, _HubTile(onTap: () => go('friendlies'), icon: GameGlyph.quick, title: l.quickFriendly, sub: l.quickFriendlySub)),
            (5, _HubTile(
              alert: missing,
              onTap: () => go('lineup'),
              icon: GameGlyph.lineup,
              title: l.matchPrep,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                Text(missing ? l.prepMissing : s.lineupAuto ? l.prepAuto : l.prepReady, style: TextStyle(color: missing ? p.danger : Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                _Progress(value: prep, color: missing ? p.danger : prep < 1 ? p.gold : p.success),
              ]),
            )),
            (3, _HubTile(upright: true, alert: needs('training_empty') || needs('training_done'), onTap: () => go('training'), icon: GameGlyph.training,
                title: left(timer('training')).isEmpty ? l.training : left(timer('training')))),
            (3, _HubTile(upright: true, onTap: () => go('stats'), icon: GameGlyph.honours, title: l.form, child: _Form(s.form))),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: row([
            (3, contract != null
                ? _HubTile(gold: true, alert: true, onTap: contract!, icon: GameGlyph.contracts, title: l.sign, sub: goalText(l, s.goal))
                : _HubTile(gold: true, onTap: () => go('quests'), icon: GameGlyph.quests, title: l.quests, sub: left(timer('daily')).isEmpty ? l.questsSub : left(timer('daily')))),
            (5, _HubTile(alert: needs('offers'), onTap: () => go('market'), icon: GameGlyph.transfers, title: l.market,
                sub: left(timer('market')).isEmpty ? l.subMarket : '${l.marketRenews} ${left(timer('market'))}')),
            (5, table),
          ]),
        ),
      ]),
    );
  }
}

/// The club's last results as five lit squares (W green, D grey, L red), newest at the reading end.
class _Form extends StatelessWidget {
  const _Form(this.form);

  final List<String> form;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = form.length > 5 ? form.sublist(form.length - 5) : form;
    if (last.isEmpty) return Text('—', style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w800));
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final r in last)
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          alignment: Alignment.center,
          decoration: ShapeDecoration(shape: GlmCut.shape(5), color: r == 'W' ? p.success : r == 'L' ? p.live : p.textMuted),
          child: Text(ar ? {'W': 'ف', 'D': 'ت', 'L': 'خ'}[r] ?? r : r, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, height: 1)),
        ),
    ]);
  }
}

/// A tile of the hub: a navy card lit from the top (gold for the quests), its glossy icon, its title in gold, a line or
/// its own content, and the green «!» when it needs the coach.
class _HubTile extends StatelessWidget {
  const _HubTile({required this.onTap, required this.icon, required this.title, this.sub, this.child, this.alert = false, this.gold = false, this.upright = false});

  /// The icon over the title, centred (the small tiles: training, the form).
  final bool upright;
  final VoidCallback onTap;
  final GameGlyph icon;
  final String title;
  final String? sub;
  final Widget? child;
  final bool alert, gold;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = Material(
      shape: GlmCut.shape(15, side: BorderSide(color: gold ? p.goldLight : GlmStage.edge)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: gold ? [GlmStage.questTop, GlmStage.questBottom] : [GlmStage.card, GlmStage.card]),
          ),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: upright
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: GameIcon(icon, size: 44))),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(title, maxLines: 1, style: TextStyle(fontFamily: GlmFonts.body, color: gold ? p.onGold : Colors.white, fontWeight: FontWeight.w700, fontSize: 14, height: 1.2))),
                  if (child != null) ...[const SizedBox(height: 3), FittedBox(fit: BoxFit.scaleDown, child: child)],
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            GameIcon(icon, size: 46),
            const SizedBox(width: 10),
            Expanded(
              child: LayoutBuilder(builder: (context, c) => FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: SizedBox(width: c.maxWidth, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: gold ? p.onGold : p.goldLight, fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 3),
                ?child,
                if (sub != null) Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: gold ? p.onGold.withValues(alpha: .8) : Colors.white70, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ])))),
            ),
          ]),
        ),
      ),
    );
    return Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: [
      PressScale(child: card),
      if (alert)
        PositionedDirectional(
          top: -6,
          start: 8,
          child: Pulse(
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: GlmStage.alert, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)]),
              child: const Text('!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, height: 1)),
            ),
          ),
        ),
    ]);
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 14,
        padding: const EdgeInsets.all(2),
        decoration: ShapeDecoration(shape: GlmCut.shape(5, side: BorderSide(color: Colors.white.withValues(alpha: .25))), color: Colors.black.withValues(alpha: .45)),
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: value.clamp(0, 1),
          child: DecoratedBox(decoration: ShapeDecoration(shape: GlmCut.shape(3), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(color, Colors.white, .3)!, color]))),
        ),
      );
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

