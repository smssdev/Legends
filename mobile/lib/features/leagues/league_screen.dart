import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import 'leagues_repository.dart';
import 'shell.dart';
import 'tabs/club_tab.dart';
import 'tabs/market_tab.dart';
import 'tabs/matches_tab.dart';
import 'tabs/more_tab.dart';
import 'tabs/team_tab.dart';

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
            IconButton(
              tooltip: l.leagueSettings,
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => editLeagueSettings(context, ref, lg!),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth > box.maxHeight;
          final content = GlmBackground(
            wide: true,
            child: AsyncView(
              value: league,
              onRetry: () => ref.invalidate(leagueProvider(widget.id)),
              data: (lg) => !hasClub
                  ? ClubTab(lg)
                  : IndexedStack(index: _tab, children: [ClubTab(lg), TeamTab(lg), MatchesTab(lg), MarketTab(lg), MoreTab(lg)]),
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
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) {
                    GameSounds.play(Sfx.tap);
                    setState(() => _tab = i);
                  },
                  groupAlignment: 0,
                  destinations: [
                    for (final (o, f, t) in items) NavigationRailDestination(icon: Icon(o), selectedIcon: Icon(f), label: Text(t)),
                  ],
                ),
                Expanded(child: content),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: content),
              NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) {
                  GameSounds.play(Sfx.tap);
                  setState(() => _tab = i);
                },
                destinations: [for (final (o, f, t) in items) NavigationDestination(icon: Icon(o), selectedIcon: Icon(f), label: t)],
              ),
            ],
          );
        },
      ),
    );
  }
}
