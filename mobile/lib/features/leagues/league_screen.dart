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

part 'league_screen_daily_tasks_card.dart';
part 'league_screen_hub_tiles.dart';
part 'league_screen_needs.dart';
part 'league_screen_coaches_tab.dart';

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
      body: LayoutBuilder(
        builder: (context, box) {
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

class _ClubTab extends ConsumerWidget {
  const _ClubTab(this.lg);

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
          _CoachesTab(lg),
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
            final stage = _Versus(s: s, leagueId: lg.id);
            final tiles = _HubTiles(
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
                  _HubTiles(
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
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    if (s.position != null && s.teams != null)
                      Text(l.position(s.position!, s.teams!), style: TextStyle(color: p.goldLight, fontSize: 12)),
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
                Text(l.treasury, style: TextStyle(color: p.textMuted, fontSize: 12)),
                const Spacer(),
                Text(
                  money(context, s.cash),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 16, color: p.success),
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
            Text(l.leagueTable, style: TextStyle(color: p.textMuted, fontSize: 12)),
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
                          style: TextStyle(fontSize: 12, color: r.mine ? p.goldLight : p.text),
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
