import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game_icons.dart';
import '../../ui/widgets/motion.dart';
import '../club/club_data.dart';
import '../club/squad_screen.dart' show money;
import 'leagues_repository.dart';

/// [Sprint 45 M1, Sprint 46] A league's screens inside its menu, the manager games' way in our own look: the menu slides
/// in from the screen's start on the arena blue, each section with its glossy icon (game_icons.dart) and its name large,
/// grouped by what it is for; and every screen's top bar (GameBar) carries the menu's button, the coins and the money.
/// go_router's ShellRoute keeps it around every `/leagues/:id/...` screen.
class LeagueShell extends ConsumerStatefulWidget {
  const LeagueShell({super.key, required this.leagueId, required this.location, required this.child});

  final int leagueId;

  /// Where we are (the route's path with its query), to light the open section.
  final String location;
  final Widget child;

  /// The shell around this screen, when there is one (its menu, its league).
  static LeagueShellState? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_InShell>()?.shell;

  /// True inside a league's shell: the league page then shows no section bar of its own.
  static bool of(BuildContext context) => maybeOf(context) != null;

  @override
  ConsumerState<LeagueShell> createState() => LeagueShellState();
}

class LeagueShellState extends ConsumerState<LeagueShell> {
  final _scaffold = GlobalKey<ScaffoldState>();

  int get leagueId => widget.leagueId;

  void openMenu() {
    GameSounds.play(Sfx.tap);
    _scaffold.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final lg = ref.watch(leagueProvider(widget.leagueId)).value;
    if (lg == null || lg.myClubId == null) return widget.child;
    return Scaffold(
      key: _scaffold,
      drawerScrimColor: Colors.black.withValues(alpha: .55),
      drawer: _Menu(leagueId: widget.leagueId, location: widget.location, leagueName: lg.name, close: () => _scaffold.currentState?.closeDrawer()),
      body: _InShell(shell: this, child: widget.child),
    );
  }
}

class _InShell extends InheritedWidget {
  const _InShell({required this.shell, required super.child});

  final LeagueShellState shell;

  @override
  bool updateShouldNotify(_InShell old) => old.shell != shell;
}

/// [Sprint 46] The top bar of every screen, in place of the plain AppBar: on the arena navy with a gold hairline under
/// it; inside a league, the menu's button at its start and the coins (green, «+» to the wallet) and the money (blue) at
/// its end, as the manager games keep them in sight. Elsewhere it is the usual bar with its back button.
class GameBar extends ConsumerWidget implements PreferredSizeWidget {
  const GameBar({super.key, this.title, this.actions, this.bottom, this.titleSpacing});

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;

  @override
  Size get preferredSize => Size.fromHeight(50 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = LeagueShell.maybeOf(context);
    final p = context.palette;
    final s = shell == null ? null : ref.watch(clubSummaryProvider(shell.leagueId)).value;
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: 50,
      titleSpacing: titleSpacing ?? (shell != null ? 4 : null),
      automaticallyImplyLeading: shell == null || canPop,
      leadingWidth: shell != null && canPop ? 104 : null,
      leading: shell == null
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(width: 6),
              _MenuButton(onTap: shell.openMenu),
              if (canPop) const BackButton(),
            ]),
      title: title,
      bottom: bottom,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: context.glm.day ? [p.panel, p.panel] : [GlmStage.deep, GlmStage.deep]),
          border: Border(bottom: BorderSide(color: p.surfaceRaised)),
        ),
      ),
      actions: [
        ...?actions,
        if (s != null) ...[
          // [Sprint 47] The approved design: the club's money (a green note) then the coins (gold), in dark pills.
          _Pill(leading: const _Coin(color: GlmStage.cash, icon: Icons.payments_rounded), value: money(context, s.cash), onTap: () => context.go('/leagues/${shell!.leagueId}/finance')),
          const SizedBox(width: 6),
          _Pill(leading: Image.asset('assets/brand/coin.png', width: 22, height: 22), value: '${s.coins}', plus: true, onTap: () => context.push('/wallet')),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: MaterialLocalizations.of(context).openAppDrawerTooltip,
        child: Material(
          shape: GlmCut.shape(12, side: const BorderSide(color: GlmStage.edge)),
          color: GlmStage.card,
          child: InkWell(
            customBorder: GlmCut.shape(10),
            onTap: onTap,
            child: const SizedBox(width: 44, height: 40, child: Icon(Icons.menu_rounded, color: Colors.white, size: 24)),
          ),
        ),
      );
}

/// A resource in the top bar: [Sprint 47] a dark pill with its icon, its number, and «+» where it can be topped up.
class _Pill extends StatelessWidget {
  const _Pill({required this.leading, required this.value, this.plus = false, this.onTap});

  final Widget leading;
  final String value;
  final bool plus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      shape: StadiumBorder(side: BorderSide(color: p.surfaceRaised)),
      clipBehavior: Clip.antiAlias,
      color: context.glm.day ? p.surface : GlmStage.pill,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 10, 0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            leading,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(value, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 18, color: p.text)),
            ),
            if (plus) Icon(Icons.add_circle_rounded, size: 18, color: context.glm.brandText),
          ]),
        ),
      ),
    );
  }
}

/// A resource's round icon in the top bar (the money's green note).
class _Coin extends StatelessWidget {
  const _Coin({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 15, color: GlmStage.deep),
      );
}

typedef _Entry = ({GameGlyph icon, String label, String path, bool push});

/// The menu: the club at its top, then every section with its icon and its name large, on the arena blue.
class _Menu extends ConsumerWidget {
  const _Menu({required this.leagueId, required this.location, required this.leagueName, required this.close});

  final int leagueId;
  final String location, leagueName;
  final VoidCallback close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final s = ref.watch(clubSummaryProvider(leagueId)).value;
    final base = '/leagues/$leagueId';
    _Entry e(GameGlyph icon, String label, String path, {bool push = false}) => (icon: icon, label: label, path: path, push: push);
    final groups = <(String, List<_Entry>)>[
      ('', [e(GameGlyph.office, l.navOffice, base)]),
      (l.navTeam, [
        e(GameGlyph.squad, l.squad, '$base/squad'),
        e(GameGlyph.lineup, l.lineup, '$base/lineup'),
        e(GameGlyph.tactics, l.tactics, '$base/tactics'),
        e(GameGlyph.specialists, l.specialists, '$base/specialists'),
        e(GameGlyph.training, l.training, '$base/training'),
        e(GameGlyph.contracts, l.contracts, '$base/contracts'),
      ]),
      (l.secCompete, [
        e(GameGlyph.match, l.matchday, '$base/matchday'),
        e(GameGlyph.table, l.leagueTable, '$base?tab=matches'),
        e(GameGlyph.friendlies, l.friendlies, '$base/friendlies'),
        e(GameGlyph.predict, l.predictions, '$base/predictions'),
        e(GameGlyph.quests, l.quests, '$base/quests'),
        e(GameGlyph.spy, l.spy, '$base/spy'),
        e(GameGlyph.alliance, l.alliance, '$base/alliance'),
        e(GameGlyph.honours, l.honours, '$base/honours'),
      ]),
      (l.secDeals, [
        e(GameGlyph.transfers, l.market, '$base/market'),
        e(GameGlyph.scout, l.scout, '$base/scout'),
      ]),
      (l.secMoney, [
        e(GameGlyph.finance, l.finance, '$base/finance'),
        e(GameGlyph.stadium, l.stadium, '$base/stadium'),
        e(GameGlyph.shop, l.wallet, '/wallet', push: true),
      ]),
      (l.secCommunity, [
        e(GameGlyph.newspaper, l.newspaper, '$base/newspaper'),
        e(GameGlyph.results, l.stats, '$base/stats'),
        e(GameGlyph.groups, l.groups, '/groups', push: true),
        e(GameGlyph.quick, l.tournaments, '/tournaments', push: true),
        e(GameGlyph.invite, l.invite, '$base?tab=more'),
      ]),
    ];
    return Drawer(
      width: 330,
      backgroundColor: GlmStage.menu,
      shape: const RoundedRectangleBorder(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmStage.menu, GlmStage.deep]),
        ),
        child: SafeArea(
          child: Column(children: [
            // The club: its crest, its name, the league, its place.
            InkWell(
              onTap: () => _go(context, base),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(color: GlmStage.band),
                child: Row(children: [
                  ClubCrest(url: s?.club.crestUrl, name: s?.club.code ?? '', size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s?.club.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                      Text(leagueName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                  if (s?.position != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: ShapeDecoration(shape: GlmCut.shape(7), gradient: LinearGradient(colors: [p.goldLight, p.gold])),
                      child: Text('${s!.position}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 20, color: p.onGold)),
                    ),
                ]),
              ),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: [
                for (final (title, entries) in groups) ...[
                  if (title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                      child: Text(title, style: const TextStyle(color: GlmStage.accent, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: .4)),
                    ),
                  // [Sprint 46, the polish] The sections slide in one after another as the menu opens.
                  for (final x in entries) FadeSlideIn(index: groups.expand((g) => g.$2).toList().indexOf(x) ~/ 2, offset: 0, child: _Item(entry: x, on: _isOn(x.path), onTap: () => _go(context, x.path, push: x.push))),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  bool _isOn(String path) {
    final base = '/leagues/$leagueId';
    if (path == base) return location == base || location == '$base?tab=club';
    return location == path || (!path.contains('?') && location.startsWith('$path/'));
  }

  void _go(BuildContext context, String path, {bool push = false}) {
    GameSounds.play(Sfx.tap);
    close();
    push ? context.push(path) : context.go(path);
  }
}

/// A section in the menu: its glossy icon and its name large; the open one on a lighter band with a gold edge.
class _Item extends StatelessWidget {
  const _Item({required this.entry, required this.on, required this.onTap});

  final _Entry entry;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? GlmStage.accent.withValues(alpha: .14) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: on ? GlmStage.accent : Colors.transparent, width: 4))),
          padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
          child: Row(children: [
            GameIcon(entry.icon, size: 46),
            const SizedBox(width: 16),
            Expanded(
              child: Text(entry.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: on ? GlmStage.accent : Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}
