import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/game_icons.dart';
import '../club/club_data.dart';
import '../club/squad_screen.dart' show money;
import 'leagues_repository.dart';

/// [Sprint 50 M2] A league's screens in the console: the dock (72px) on the screen's start side and the screen beside
/// it, the app's landscape version of the site's section row (AppShell.vue: gold icons over their names, the open one
/// gold with its gold bar). A section with several pages opens their list beside the dock, as the site's dropdowns do.
/// go_router's ShellRoute keeps it around every `/leagues/:id/...` screen; each screen keeps its own top bar (GameBar).
class LeagueShell extends ConsumerStatefulWidget {
  const LeagueShell({super.key, required this.leagueId, required this.location, required this.child});

  final int leagueId;

  /// Where we are (the route's path with its query), to light the open section.
  final String location;
  final Widget child;

  /// The shell around this screen, when there is one (its dock, its league).
  static LeagueShellState? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_InShell>()?.shell;

  /// True inside a league's shell: the league page then shows no section bar of its own.
  static bool of(BuildContext context) => maybeOf(context) != null;

  @override
  ConsumerState<LeagueShell> createState() => LeagueShellState();
}

class LeagueShellState extends ConsumerState<LeagueShell> {
  int get leagueId => widget.leagueId;

  @override
  Widget build(BuildContext context) {
    final lg = ref.watch(leagueProvider(widget.leagueId)).value;
    if (lg == null || lg.myClubId == null) return widget.child;
    return Material(
      color: GlmStage.deep,
      child: Row(children: [
        SafeArea(right: false, left: true, child: ConsoleDock(leagueId: widget.leagueId, location: widget.location)),
        Expanded(child: _InShell(shell: this, child: widget.child)),
      ]),
    );
  }
}

class _InShell extends InheritedWidget {
  const _InShell({required this.shell, required super.child});

  final LeagueShellState shell;

  @override
  bool updateShouldNotify(_InShell old) => old.shell != shell;
}

/// [Sprint 50 M2] The top bar of every screen, as the site's (.shell-top): night lit from the emerald with the
/// emerald-to-gold seam under it, 42px high. Inside a league: the coins in a gold pill and the club's money in an emerald
/// one (each with «+»), the next match's countdown, and the messages. Elsewhere it is the usual bar with its back button.
class GameBar extends ConsumerWidget implements PreferredSizeWidget {
  const GameBar({super.key, this.title, this.actions, this.bottom, this.titleSpacing});

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;

  static const height = 42.0;

  @override
  Size get preferredSize => Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = LeagueShell.maybeOf(context);
    final s = shell == null ? null : ref.watch(clubSummaryProvider(shell.leagueId)).value;
    return AppBar(
      toolbarHeight: height,
      titleSpacing: titleSpacing,
      // [Sprint 51 F1] The game's font: AppBar replaces the theme's title style instead of merging into it, so without its
      // family the title fell back to the system's.
      titleTextStyle: const TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
      title: title,
      bottom: bottom,
      flexibleSpace: const _TopBarGround(),
      actions: [
        ...?actions,
        if (s != null) ...[
          if (s.matchAt != null && s.matchStatus != 'live') _Countdown(at: s.matchAt!),
          const SizedBox(width: 6),
          // The site's order: the coins, then the club's money.
          CoinsPill(value: '${s.coins}', onTap: () => context.push('/wallet')),
          const SizedBox(width: 6),
          MoneyPill(value: money(context, s.cash), onTap: () => context.go('/leagues/${shell!.leagueId}/finance')),
          const SizedBox(width: 6),
          BarIcon(icon: Icons.chat_bubble_outline_rounded, label: L.of(context).inbox, onTap: () => context.push('/inbox')),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// The top bar's ground: the site's .shell-top (the emerald mixed into the panel, down to the deep night) and its seam.
class _TopBarGround extends StatelessWidget {
  const _TopBarGround();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: context.glm.day ? [p.panel, p.panel] : [Color.lerp(p.panel, p.brand, .22)!, p.panel, p.bgDeep],
          stops: context.glm.day ? null : const [0, .55, 1],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 2,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, p.brandLight, p.gold, Colors.transparent], stops: const [0, .25, .75, 1])),
        ),
      ),
    );
  }
}

/// [Sprint 50] The coins, as the site's .pill-coins: a gold pill with dark figures, «+» to the wallet.
class CoinsPill extends StatelessWidget {
  const CoinsPill({super.key, required this.value, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '${L.of(context).wallet}: $value',
      child: Material(
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.goldLight, p.gold, p.goldDark], stops: const [0, .6, 1])),
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 32,
              padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 0),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/brand/coin.png', width: 20, height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(value, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 16, color: p.onGold)),
                ),
                _Plus(bg: p.bg, fg: p.goldLight),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// [Sprint 50] The club's money, as the site's .pill-money: an emerald-tinted pill with green figures, «+» to finance.
class MoneyPill extends StatelessWidget {
  const MoneyPill({super.key, required this.value, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '${L.of(context).finance}: $value',
      child: Material(
        color: p.success.withValues(alpha: .18),
        shape: StadiumBorder(side: BorderSide(color: p.success.withValues(alpha: .35))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 32,
            padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 4, 0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(value, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 16, color: p.success)),
              const SizedBox(width: 5),
              _Plus(bg: p.success, fg: p.bgDeep),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Plus extends StatelessWidget {
  const _Plus({required this.bg, required this.fg});

  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
        width: 22, height: 22, alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(Icons.add_rounded, size: 16, color: fg),
      );
}

/// [Sprint 50] A round icon of the top bar, as the site's .bar-icon (a 44px touch on a 36px circle), with its badge.
class BarIcon extends StatelessWidget {
  const BarIcon({super.key, required this.icon, required this.label, this.onTap, this.badge});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: p.text.withValues(alpha: .1), shape: BoxShape.circle),
                child: Icon(icon, size: 19, color: p.text),
              ),
              if (badge != null)
                PositionedDirectional(
                  top: -3, end: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(color: p.live, borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text(badge!, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The next match's countdown on the top bar (the site's timers), ticking each second.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.at});

  final DateTime at;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final _tick = Stream<int>.periodic(const Duration(seconds: 1), (i) => i);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return StreamBuilder<int>(
      stream: _tick,
      builder: (context, _) {
        final left = widget.at.difference(DateTime.now());
        if (left.isNegative || left.inHours >= 100) return const SizedBox.shrink();
        String two(int n) => n.toString().padLeft(2, '0');
        final text = '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';
        return Semantics(
          label: '${L.of(context).nextMatch}: $text',
          excludeSemantics: true,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: p.text.withValues(alpha: .1), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.schedule_rounded, size: 16, color: p.gold),
              const SizedBox(width: 5),
              Text(text, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 15, color: p.text)),
            ]),
          ),
        );
      },
    );
  }
}

typedef _Entry = ({GameGlyph icon, String label, String path, bool push});

/// [Sprint 50 M2] The dock: the site's section row stood on its side, 72px on the screen's start. The club's crest at
/// its top (to the office), then each section: a gold icon over its name, the open one gold with a gold bar on the
/// dock's edge and a light ground. A section of one page goes there; a section of several opens their list beside the
/// dock (the site's .nav-panel: the open page on the brand green). A live match pulses red on the match's section.
class ConsoleDock extends ConsumerWidget {
  const ConsoleDock({super.key, required this.leagueId, required this.location});

  final int leagueId;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final s = ref.watch(clubSummaryProvider(leagueId)).value;
    final base = '/leagues/$leagueId';
    _Entry e(GameGlyph icon, String label, String path, {bool push = false}) => (icon: icon, label: label, path: path, push: push);
    final sections = <_Section>[
      (icon: Icons.home_rounded, label: l.navOffice, entries: [e(GameGlyph.office, l.navOffice, base)], badge: null),
      (icon: Icons.checkroom_rounded, label: l.navTeam, entries: [
        e(GameGlyph.squad, l.squad, '$base/squad'),
        e(GameGlyph.lineup, l.lineup, '$base/lineup'),
        e(GameGlyph.specialists, l.specialists, '$base/specialists'),
        e(GameGlyph.training, l.training, '$base/training'),
        e(GameGlyph.contracts, l.contracts, '$base/contracts'),
      ], badge: null),
      (icon: Icons.tune_rounded, label: l.tactics, entries: [e(GameGlyph.tactics, l.tactics, '$base/tactics')], badge: null),
      (icon: Icons.sports_soccer_rounded, label: l.secCompete, entries: [
        e(GameGlyph.match, l.matchday, '$base/matchday'),
        e(GameGlyph.table, l.leagueTable, '$base?tab=matches'),
        e(GameGlyph.friendlies, l.friendlies, '$base/friendlies'),
        e(GameGlyph.predict, l.predictions, '$base/predictions'),
        e(GameGlyph.quests, l.quests, '$base/quests'),
        e(GameGlyph.spy, l.spy, '$base/spy'),
        e(GameGlyph.alliance, l.alliance, '$base/alliance'),
        e(GameGlyph.honours, l.honours, '$base/honours'),
      ], badge: s?.matchStatus == 'live' ? 'live' : null),
      (icon: Icons.storefront_rounded, label: l.secDeals, entries: [
        e(GameGlyph.transfers, l.market, '$base/market'),
        e(GameGlyph.scout, l.scout, '$base/scout'),
      ], badge: null),
      (icon: Icons.stadium_rounded, label: l.secMoney, entries: [
        e(GameGlyph.stadium, l.stadium, '$base/stadium'),
        e(GameGlyph.finance, l.finance, '$base/finance'),
        e(GameGlyph.shop, l.wallet, '/wallet', push: true),
      ], badge: null),
      (icon: Icons.forum_rounded, label: l.secCommunity, entries: [
        e(GameGlyph.groups, l.groups, '/groups', push: true),
        e(GameGlyph.newspaper, l.newspaper, '$base/newspaper'),
        e(GameGlyph.results, l.stats, '$base/stats'),
        e(GameGlyph.quick, l.tournaments, '/tournaments', push: true),
        e(GameGlyph.invite, l.invite, '$base?tab=more'),
      ], badge: null),
    ];
    return Container(
      width: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.bgDeep.withValues(alpha: .92), p.panel.withValues(alpha: .88)]),
        border: BorderDirectional(end: BorderSide(color: p.gold.withValues(alpha: .55))),
      ),
      child: Column(children: [
        // The club's crest: back to the office.
        Semantics(
          button: true,
          label: s?.club.name ?? l.navOffice,
          child: InkWell(
            onTap: () => _go(context, base),
            child: SizedBox(height: 50, child: Center(child: ClubCrest(url: s?.club.crestUrl, name: s?.club.code ?? '', size: 34))),
          ),
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            for (final x in sections) _DockItem(section: x, on: x.entries.any((y) => _isOn(y.path)), isOn: _isOn, go: (path, push) => _go(context, path, push: push)),
          ]),
        ),
      ]),
    );
  }

  bool _isOn(String path) {
    final base = '/leagues/$leagueId';
    if (path == base) return location == base || location == '$base?tab=club';
    return location == path || (!path.contains('?') && location.startsWith('$path/'));
  }

  void _go(BuildContext context, String path, {bool push = false}) {
    GameSounds.play(Sfx.tap);
    push ? context.push(path) : context.go(path);
  }
}

typedef _Section = ({IconData icon, String label, List<_Entry> entries, String? badge});

/// A section in the dock: its gold icon over its name; several pages open their list beside it.
class _DockItem extends StatelessWidget {
  const _DockItem({required this.section, required this.on, required this.isOn, required this.go});

  final _Section section;
  final bool on;
  final bool Function(String path) isOn;
  final void Function(String path, bool push) go;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget item(VoidCallback onTap) => Semantics(
          button: true,
          selected: on,
          label: section.label,
          excludeSemantics: true,
          child: Material(
            color: on ? p.text.withValues(alpha: .06) : Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(border: BorderDirectional(end: BorderSide(color: on ? p.gold : Colors.transparent, width: 3))),
                child: Stack(alignment: Alignment.center, children: [
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(section.icon, size: 22, color: p.gold, shadows: const [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 2))]),
                    const SizedBox(height: 2),
                    Text(section.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: on ? p.goldLight : p.text)),
                  ]),
                  if (section.badge == 'live') const PositionedDirectional(top: 6, end: 14, child: _LiveDot()),
                ]),
              ),
            ),
          ),
        );
    if (section.entries.length == 1) {
      final x = section.entries.first;
      return item(() => go(x.path, x.push));
    }
    return MenuAnchor(
      alignmentOffset: const Offset(4, -54),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.surface),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: p.gold.withValues(alpha: .3)))),
      ),
      menuChildren: [
        for (final x in section.entries)
          MenuItemButton(
            onPressed: () => go(x.path, x.push),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(200, 44)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              backgroundColor: WidgetStatePropertyAll(isOn(x.path) ? p.brand : Colors.transparent),
              foregroundColor: WidgetStatePropertyAll(isOn(x.path) ? Colors.white : p.textSoft),
              textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            leadingIcon: GameIcon(x.icon, size: 26),
            child: Text(x.label),
          ),
      ],
      builder: (context, controller, _) => item(() => controller.isOpen ? controller.close() : controller.open()),
    );
  }
}

/// The live match's pulsing red dot (the site's animate-pulse-ring on bg-live).
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = context.palette.live;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: 9, height: 9,
        decoration: BoxDecoration(color: live, shape: BoxShape.circle, boxShadow: [BoxShadow(color: live.withValues(alpha: 1 - _c.value), spreadRadius: 6 * _c.value)]),
      ),
    );
  }
}
