import '../../ui/widgets/glm_icon.dart';
import '../../ui/art_palette.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/motion.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/game_icons.dart';
import '../../ui/widgets/kit.dart';
import '../../ui/widgets/stadium.dart';
import '../../ui/widgets/brand.dart';
import '../leagues/widgets.dart' show goalText;
import 'club_data.dart';
import 'team_data.dart';
import '../leagues/shell.dart';
import '../../ui/widgets/target.dart';
import '../../ui/widgets/player_name.dart';
import '../../ui/size_class.dart';
import '../../ui/widgets/action_bar.dart';
import '../../ui/widgets/glm_button.dart';

import 'package:go_router/go_router.dart';

import '../leagues/leagues_repository.dart' show leagueClubsProvider;
import '../market/offer_screen.dart';
import '../market/sell_sheet.dart' show sellFromSquad;

part 'squad_screen_header_delegate.dart';
part 'squad_screen_hero_strip.dart';
part 'squad_screen_player_row.dart';
part 'squad_screen_rival.dart';

/// [Sprint 17 F1, Sprint 45 M3] The squad as the manager games show it, a table: the position in its line's colour,
/// the name, age, rating, potential, fitness as a bar, value and who cannot play; a tap on a column sorts by it (again:
/// the other way), the lines filter it, and a tap on a player opens his card.
///
/// [X114, the owner's request 2026-11-22] Any other club of the league in the same table ([clubId], from «Rival squads»
/// in the bar), its players' numbers only (never its tactics); and a player of mine sold from his card, as on the site.
class SquadScreen extends ConsumerStatefulWidget {
  const SquadScreen({super.key, required this.leagueId, this.clubId});

  final int leagueId;

  /// Another club of the league; null is mine.
  final int? clubId;

  @override
  ConsumerState<SquadScreen> createState() => _SquadScreenState();
}

enum _Col { pos, name, age, ovr, pot, fit, value }

class _SquadScreenState extends ConsumerState<SquadScreen> {
  _Col _sort = _Col.pos;
  bool _desc = false;
  String? _line;

  /// [Sprint 60 F4] The player whose card is open beside the table, and whether the screen is too narrow for it (the
  /// room the screen has, not the window's: a sheet then).
  Player? _card;

  /// [Sprint 73 D2] The team's hero open or closed by hand; null is the screen's own choice (closed on a short one).
  bool? _hero;
  bool _narrow = false;

  static const _lineOrder = {'gk': 0, 'def': 1, 'mid': 2, 'att': 3};

  void _by(_Col c) => setState(() {
    _desc = _sort == c ? !_desc : c != _Col.pos && c != _Col.name;
    _sort = c;
  });

  List<Player> _rows(TeamData team) {
    final xs = [
      for (final p in team.players)
        if (_line == null || p.line == _line) p,
    ];
    int cmp(Player a, Player b) => switch (_sort) {
      _Col.pos =>
        (_lineOrder[a.line] ?? 9).compareTo(_lineOrder[b.line] ?? 9) != 0
            ? (_lineOrder[a.line] ?? 9).compareTo(_lineOrder[b.line] ?? 9)
            : b.overall.compareTo(a.overall),
      _Col.name => a.name.compareTo(b.name),
      _Col.age => a.age.compareTo(b.age),
      _Col.ovr => a.overall.compareTo(b.overall),
      _Col.pot => a.potential.compareTo(b.potential),
      _Col.fit => a.fitness.compareTo(b.fitness),
      _Col.value => a.value.compareTo(b.value),
    };
    xs.sort((a, b) => _desc ? cmp(b, a) : cmp(a, b));
    return xs;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final rivalId = widget.clubId;
    final rivalValue = rivalId == null ? null : ref.watch(rivalSquadProvider((widget.leagueId, rivalId)));
    final rival = rivalValue?.value;
    final AsyncValue<TeamData> value = rivalValue == null ? ref.watch(teamProvider(widget.leagueId)) : rivalValue.whenData((r) => r.team);
    return Scaffold(
      appBar: GameBar(title: Text(rivalId == null ? l.squad : rival?.name ?? l.rivalSquads)),
      // [X114] The screen's actions in its bar: the rival squads, and back to mine from one.
      bottomNavigationBar: SafeArea(
        top: false,
        child: GlmActionBar(
          actions: [
            if (rivalId != null)
              GlmActionItem(
                icon: const GlmIcon(GlmIcons.team),
                label: l.mySquad,
                onTap: () => context.canPop() ? context.pop() : context.go('/leagues/${widget.leagueId}/squad'),
              ),
            GlmActionItem(icon: const GlmIcon(GlmIcons.eye), label: l.rivalSquads, onTap: () => _pickRival(context)),
          ],
        ),
      ),
      body: GlmBackground(
        wide: true,
        child: RefreshIndicator(
          onRefresh: () => rivalId == null
              ? ref.refresh(teamProvider(widget.leagueId).future)
              : ref.refresh(rivalSquadProvider((widget.leagueId, rivalId)).future),
          child: AsyncView(
            value: value,
            onRetry: () => rivalId == null
                ? ref.invalidate(teamProvider(widget.leagueId))
                : ref.invalidate(rivalSquadProvider((widget.leagueId, rivalId))),
            data: (team) {
              final summary = ref.watch(clubSummaryProvider(widget.leagueId)).value;
              final rows = _rows(team);
              final short = GlmFit.shortOf(context);
              final heroOpen = rival == null && (_hero ?? !short);
              final groups = [('att', l.groupAtt), ('mid', l.groupMid), ('def', l.groupDef), ('gk', l.groupGk)];
              // [Sprint 46, the owner's screenshots] The squad as the manager games show it: a band of the club's facts, the
              // team's rating with each line's over a little pitch and its key players, then the white table by line.
              final table = CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Fit(
                      child: rival != null ? _RivalBand(rival: rival) : _InfoBand(team: team, summary: summary),
                    ),
                  ),
                  // [Sprint 73 D2] The players first on a phone held sideways (the band, the hero and the table's head took
                  // 310 of its 360, and not one player showed): the hero opens from its strip, and is open where there
                  // is room for it and the table both.
                  if (heroOpen)
                    SliverToBoxAdapter(
                      child: _Fit(
                        child: _TeamHero(team: team, summary: summary),
                      ),
                    ),
                  if (short && rival == null)
                    SliverToBoxAdapter(
                      child: _HeroStrip(open: heroOpen, onTap: () => setState(() => _hero = !heroOpen)),
                    ),
                  SliverPersistentHeader(pinned: true, delegate: _HeaderDelegate(this)),
                  for (final (line, title) in groups)
                    if (rows.any((p) => p.line == line)) ...[
                      SliverToBoxAdapter(child: _GroupTitle(title)),
                      SliverList.builder(
                        itemCount: rows.where((p) => p.line == line).length,
                        itemBuilder: (context, i) {
                          final pl = rows.where((p) => p.line == line).elementAt(i);
                          return FadeSlideIn(
                            index: i,
                            offset: 12,
                            child: _Row(
                              pl,
                              captain: team.captain == pl.id,
                              // [Sprint 60 F4] Beside the table on a landscape screen; a sheet where there is no room.
                              onTap: () => _narrow
                                  ? showPlayerCard(context, pl, action: (context) => _cardAction(context, pl, rival))
                                  : setState(() => _card = pl),
                            ),
                          );
                        },
                      ),
                    ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
              final card = _card == null ? null : team.players.where((x) => x.id == _card!.id).firstOrNull ?? _card;
              return LayoutBuilder(
                builder: (context, box) {
                  _narrow = GlmFit.isNarrow(box.maxWidth);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: table),
                      if (card != null && !_narrow)
                        SizedBox(
                          width: (box.maxWidth * .46).clamp(0.0, 340.0),
                          child: PlayerCardPanel(
                            player: card,
                            close: () => setState(() => _card = null),
                            action: _cardAction(context, card, rival),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// On a narrow screen, a wide piece drawn at the landscape width and scaled down to fit.
class _Fit extends StatelessWidget {
  const _Fit({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (GlmFit.isWide(box.maxWidth)) return child;
      return FittedBox(
        fit: BoxFit.fitWidth,
        child: SizedBox(width: 840, child: child),
      );
    },
  );
}

/// The club's facts in one navy band: its place, the board's goal, the formation, the squad's value.
class _InfoBand extends StatelessWidget {
  const _InfoBand({required this.team, required this.summary});

  final TeamData team;
  final ClubSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    Widget fact(Widget icon, String label, String value) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: ShapeDecoration(shape: GlmCut.shape(8), color: Colors.black.withValues(alpha: .28)),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                style: glmText(GlmType.body, color: glmNight.text, fontWeight: FontWeight.w700, height: 1.15),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: glmText(
                GlmType.title,
                fontFamily: GlmFonts.numbers,
                fontFamilyFallback: const [GlmFonts.body],
                fontWeight: FontWeight.w800,
                color: p.goldLight,
              ),
            ),
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmStage.cardRaised, GlmStage.card]),
      ),
      child: Row(
        children: [
          fact(const GameIcon(GameGlyph.honours, size: 26), l.leaguePlace, summary?.position == null ? '—' : '${summary!.position}'),
          fact(
            const GameIcon(GameGlyph.contracts, size: 26),
            l.boardGoal,
            summary?.goal == null ? '—' : goalText(l, summary!.goal).replaceAll(RegExp(r'^[^:]*:\s*'), ''),
          ),
          fact(const GameIcon(GameGlyph.lineup, size: 26), l.formation, team.lineup.formation),
          fact(Image.asset('assets/brand/coin.png', width: 24, height: 24), l.squadValue, money(context, team.squadValue)),
        ],
      ),
    );
  }
}

/// The team's rating as a great ring and each line's in a bubble over a little pitch; the club, and its key players.
class _TeamHero extends StatelessWidget {
  const _TeamHero({required this.team, required this.summary});

  final TeamData team;
  final ClubSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final starters = [for (final id in team.lineup.starters) ?team.byId(id)];
    final rating = starters.isEmpty ? 0 : (starters.fold(0, (a, b) => a + b.overall) / starters.length).round();
    Player? best(int Function(Player) by, [bool Function(Player)? where]) {
      final xs = team.players.where(where ?? (_) => true).toList()..sort((a, b) => by(b).compareTo(by(a)));
      return xs.firstOrNull;
    }

    final keys = [
      (l.bestRated, best((x) => x.overall), (Player x) => '${x.overall}'),
      (l.starPlayer, best((x) => x.value), (Player x) => money(context, x.value)),
      (l.bestProspect, best((x) => x.potential, (x) => x.age <= 21), (Player x) => '${x.potential}'),
    ];
    Widget bubble(String label, int? v) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ArcGauge(value: v ?? 0, size: 58, label: label),
        CustomPaint(size: const Size(10, 6), painter: _Pin()),
      ],
    );
    return SizedBox(
      height: 206,
      child: StadiumBackdrop(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: Row(
            children: [
              // The club and its key players.
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        ClubCrest(url: summary?.club.crestUrl, name: summary?.club.code ?? '', size: 44),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            summary?.club.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: glmText(
                              GlmType.display,
                              fontFamily: GlmFonts.numbers,
                              fontWeight: FontWeight.w800,
                              color: glmNight.text,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final (label, pl, value) in keys)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 92,
                              child: Text(
                                label,
                                style: glmText(GlmType.body, color: glmNight.text, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                color: Colors.black.withValues(alpha: .35),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pl?.name ?? '—',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                        style: glmText(
                                          GlmType.bodyLg,
                                          fontFamily: GlmFonts.numbers,
                                          fontWeight: FontWeight.w800,
                                          color: glmNight.text,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      pl == null ? '' : value(pl),
                                      textDirection: TextDirection.ltr,
                                      style: glmText(
                                        GlmType.bodyLg,
                                        fontFamily: GlmFonts.numbers,
                                        fontWeight: FontWeight.w800,
                                        color: p.goldLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // The lines over the pitch, the team's ring at the end.
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 6,
                            height: 60,
                            child: CustomPaint(painter: _MiniPitch(p.pitch, p.pitchDark)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 44),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final (k, label) in [
                                    ('gk', l.lineGkShort),
                                    ('def', l.lineDefShort),
                                    ('mid', l.lineMidShort),
                                    ('att', l.lineAttShort),
                                  ])
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: bubble(label, team.lines[k])),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ArcGauge(value: rating, size: 136, label: l.teamRating, stroke: 9),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
