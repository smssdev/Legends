import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/cut.dart';
import '../club/club_data.dart';
import '../club/squad_screen.dart' show money;
import 'leagues_repository.dart';

/// [Sprint 45 M1] The league's menu, always there on a wide (landscape) screen, as in the great manager games and our
/// own way: the club at the top (its crest, name and place), the money and the coins, the next match counting down,
/// then every section of the club grouped by what it is for, the one open lit in gold. The screens open inside it
/// (go_router's ShellRoute), so moving between them is one tap from anywhere. On a narrow screen: the screen alone.
class LeagueShell extends ConsumerWidget {
  const LeagueShell({super.key, required this.leagueId, required this.location, required this.child});

  final int leagueId;

  /// Where we are (the route's path with its query), to light the open section.
  final String location;
  final Widget child;

  /// True inside the shell's menu: the league page then shows no rail of its own.
  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_InShell>() != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lg = ref.watch(leagueProvider(leagueId)).value;
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < 640 || lg == null || lg.myClubId == null) return child;
      return Material(
        color: context.palette.bgDeep,
        child: Row(children: [
          SizedBox(width: 200, child: _Menu(leagueId: leagueId, location: location, leagueName: lg.name)),
          Expanded(child: _InShell(child: ClipRect(child: child))),
        ]),
      );
    });
  }
}

class _InShell extends InheritedWidget {
  const _InShell({required super.child});

  @override
  bool updateShouldNotify(_InShell old) => false;
}

typedef _Entry = ({IconData icon, String label, String path});

class _Menu extends ConsumerWidget {
  const _Menu({required this.leagueId, required this.location, required this.leagueName});

  final int leagueId;
  final String location, leagueName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final s = ref.watch(clubSummaryProvider(leagueId)).value;
    final base = '/leagues/$leagueId';
    final groups = <(String, List<_Entry>)>[
      ('', [(icon: Icons.space_dashboard_rounded, label: l.navOffice, path: base)]),
      (l.navTeam, [
        (icon: Icons.groups_rounded, label: l.squad, path: '$base/squad'),
        (icon: Icons.grid_view_rounded, label: l.lineup, path: '$base/lineup'),
        (icon: Icons.tune_rounded, label: l.tactics, path: '$base/tactics'),
        (icon: Icons.fitness_center_rounded, label: l.training, path: '$base/training'),
      ]),
      (l.secCompete, [
        (icon: Icons.calendar_month_rounded, label: l.tileFixtures, path: '$base?tab=matches'),
        (icon: Icons.sports_rounded, label: l.matchday, path: '$base/matchday'),
      ]),
      (l.secDeals, [
        (icon: Icons.storefront_rounded, label: l.market, path: '$base/market'),
        (icon: Icons.travel_explore_rounded, label: l.scout, path: '$base/scout'),
      ]),
      (l.secMoney, [
        (icon: Icons.account_balance_wallet_rounded, label: l.finance, path: '$base/finance'),
        (icon: Icons.stadium_rounded, label: l.stadium, path: '$base/stadium'),
      ]),
      ('', [(icon: Icons.apps_rounded, label: l.navMore, path: '$base?tab=more')]),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(p.bgDeep, p.brandDark, .25)!, p.bgDeep]),
        border: BorderDirectional(end: BorderSide(color: p.gold.withValues(alpha: .18))),
      ),
      child: SafeArea(
        right: false,
        left: false,
        child: Column(children: [
          // The club: crest, name, the league, its place.
          InkWell(
            onTap: () => _go(context, base),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(children: [
                ClubCrest(url: s?.club.crestUrl, name: s?.club.code ?? '', size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s?.club.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(leagueName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textMuted, fontSize: 11)),
                  ]),
                ),
                if (s?.position != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: ShapeDecoration(shape: GlmCut.shape(6), color: p.gold.withValues(alpha: .16)),
                    child: Text('${s!.position}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16, color: context.glm.goldText)),
                  ),
              ]),
            ),
          ),
          // The money and the coins, then the next match's clock.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Expanded(child: _Resource(icon: Icon(Icons.payments_rounded, size: 16, color: p.success), value: s == null ? '—' : money(context, s.cash))),
              const SizedBox(width: 6),
              Expanded(child: _Resource(icon: Image.asset('assets/brand/coin.png', width: 16, height: 16), value: s == null ? '—' : '${s.coins}', onTap: () => context.push('/wallet'))),
            ]),
          ),
          if (s?.matchAt != null) _NextClock(at: s!.matchAt!, opponent: s.next?.code ?? '', live: s.matchId != null, onTap: () => _go(context, s.matchId != null ? '/match/${s.matchId}' : '$base/matchday', push: s.matchId != null)),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(8, 4, 8, 10), children: [
              for (final (title, entries) in groups) ...[
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
                    child: Text(title, style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: .5)),
                  ),
                for (final e in entries) _Item(entry: e, on: _isOn(e.path), onTap: () => _go(context, e.path)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  /// The section a location belongs to: its own path (the office only when nothing else matches).
  bool _isOn(String path) {
    final base = '/leagues/$leagueId';
    if (path == base) return location == base || location == '$base?tab=club';
    return location == path || (path.contains('?') ? false : location.startsWith('$path/'));
  }

  void _go(BuildContext context, String path, {bool push = false}) {
    GameSounds.play(Sfx.tap);
    push ? context.push(path) : context.go(path);
  }
}

class _Resource extends StatelessWidget {
  const _Resource({required this.icon, required this.value, this.onTap});

  final Widget icon;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.black.withValues(alpha: .25),
      shape: GlmCut.shape(8, side: BorderSide(color: Colors.white.withValues(alpha: .06))),
      child: InkWell(
        customBorder: GlmCut.shape(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            icon,
            const SizedBox(width: 6),
            Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, textAlign: TextAlign.start,
                style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16, color: p.text))),
          ]),
        ),
      ),
    );
  }
}

/// The next match counting down (live: a red pulse and the way in).
class _NextClock extends StatefulWidget {
  const _NextClock({required this.at, required this.opponent, required this.live, required this.onTap});

  final DateTime at;
  final String opponent;
  final bool live;
  final VoidCallback onTap;

  @override
  State<_NextClock> createState() => _NextClockState();
}

class _NextClockState extends State<_NextClock> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = L.of(context);
    final left = widget.at.difference(DateTime.now());
    final clock = widget.live
        ? l.liveBadge
        : left.isNegative
            ? '—'
            : left.inDays >= 1
                ? (Localizations.localeOf(context).languageCode == 'ar' ? '${left.inDays}ي ${left.inHours % 24}س' : '${left.inDays}d ${left.inHours % 24}h')
                : '${left.inHours.toString().padLeft(2, '0')}:${(left.inMinutes % 60).toString().padLeft(2, '0')}';
    final c = widget.live ? p.danger : p.gold;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Material(
        shape: GlmCut.shape(10, side: BorderSide(color: c.withValues(alpha: .5))),
        color: c.withValues(alpha: .12),
        child: InkWell(
          customBorder: GlmCut.shape(10),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(children: [
              Icon(widget.live ? Icons.sensors_rounded : Icons.timer_rounded, size: 16, color: c),
              const SizedBox(width: 6),
              Expanded(child: Text(widget.opponent, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
              Text(clock, style: TextStyle(fontFamily: GlmFonts.numbers, fontFamilyFallback: const [GlmFonts.body], fontWeight: FontWeight.w800, fontSize: 16, color: widget.live ? p.danger : context.glm.goldText)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A section in the menu: its icon and name; the open one on a gold slab in the Legend Cut.
class _Item extends StatelessWidget {
  const _Item({required this.entry, required this.on, required this.onTap});

  final _Entry entry;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        shape: GlmCut.shape(GlmCut.badge),
        color: on ? p.gold.withValues(alpha: .16) : Colors.transparent,
        child: InkWell(
          customBorder: GlmCut.shape(GlmCut.badge),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GlmSize.touchMin),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: on ? 26 : 0,
                decoration: BoxDecoration(color: p.gold, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 9),
              Icon(entry.icon, size: 20, color: on ? p.gold : p.textSoft),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: on ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: on ? context.glm.goldText : p.text))),
            ]),
          ),
        ),
      ),
    );
  }
}
