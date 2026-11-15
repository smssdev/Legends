import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/nav.g.dart';
import '../../ui/size_class.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_icon.dart';
import '../club/club_data.dart';
import '../club/squad_screen.dart' show money;
import 'leagues_repository.dart';
import '../../ui/widgets/target.dart';
import '../../ui/widgets/motion.dart';

part 'shell_money_pill.dart';

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
    // [Sprint 72 R4] The dock stands on the screen's start side: the right in Arabic, the left in English. It takes the
    // notch's inset of its own side, and the screen beside it the other side's (it was `left` always: in Arabic an
    // empty strip beside the dock, and the dock itself under a notch on the right).
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: GlmStage.deep,
      child: Row(
        children: [
          SafeArea(
            left: !rtl,
            right: rtl,
            child: ConsoleDock(leagueId: widget.leagueId, location: widget.location),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: !rtl,
              removeRight: rtl,
              child: _InShell(shell: this, child: widget.child),
            ),
          ),
        ],
      ),
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
      titleTextStyle: glmText(GlmType.bodyLg, fontFamily: GlmFonts.body, fontWeight: FontWeight.w800, color: Colors.white),
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.glm.day ? [p.panel, p.panel] : [Color.lerp(p.panel, p.brand, .22)!, p.panel, p.bgDeep],
          stops: context.glm.day ? null : const [0, .55, 1],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, p.brandLight, p.gold, Colors.transparent], stops: const [0, .25, .75, 1]),
          ),
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
    // [Sprint 65 F3] Drawn 32 high in the 42 bar, answering the finger over 48.
    return GlmTarget(
      child: Semantics(
        button: true,
        label: '${L.of(context).wallet}: $value',
        child: Material(
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [p.goldLight, p.gold, p.goldDark],
                stops: const [0, .6, 1],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 32,
                padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/brand/coin.png', width: 20, height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        value,
                        textDirection: TextDirection.ltr,
                        style: glmText(GlmType.bodyLg, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: p.onGold),
                      ),
                    ),
                    _Plus(bg: p.bg, fg: p.goldLight),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
