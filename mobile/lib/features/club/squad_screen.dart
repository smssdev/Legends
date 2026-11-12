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

/// [Sprint 17 F1, Sprint 45 M3] The squad as the manager games show it, a table: the position in its line's colour,
/// the name, age, rating, potential, fitness as a bar, value and who cannot play; a tap on a column sorts by it (again:
/// the other way), the lines filter it, and a tap on a player opens his card.
class SquadScreen extends ConsumerStatefulWidget {
  const SquadScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<SquadScreen> createState() => _SquadScreenState();
}

enum _Col { pos, name, age, ovr, pot, fit, value }

class _SquadScreenState extends ConsumerState<SquadScreen> {
  _Col _sort = _Col.pos;
  bool _desc = false;
  String? _line;

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
    return Scaffold(
      appBar: GameBar(title: Text(l.squad)),
      body: GlmBackground(
        wide: true,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(teamProvider(widget.leagueId).future),
          child: AsyncView(
            value: ref.watch(teamProvider(widget.leagueId)),
            onRetry: () => ref.invalidate(teamProvider(widget.leagueId)),
            data: (team) {
              final summary = ref.watch(clubSummaryProvider(widget.leagueId)).value;
              final rows = _rows(team);
              final groups = [('att', l.groupAtt), ('mid', l.groupMid), ('def', l.groupDef), ('gk', l.groupGk)];
              // [Sprint 46, the owner's screenshots] The squad as the manager games show it: a band of the club's facts, the
              // team's rating with each line's over a little pitch and its key players, then the white table by line.
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Fit(
                      child: _InfoBand(team: team, summary: summary),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Fit(
                      child: _TeamHero(team: team, summary: summary),
                    ),
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
                            child: _Row(pl, captain: team.captain == pl.id, onTap: () => showPlayerCard(context, pl)),
                          );
                        },
                      ),
                    ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
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
      if (box.maxWidth >= 840) return child;
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: GlmFonts.numbers,
                fontFamilyFallback: const [GlmFonts.body],
                fontWeight: FontWeight.w800,
                fontSize: 19,
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
                            style: const TextStyle(
                              fontFamily: GlmFonts.numbers,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: Colors.white,
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
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
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
                                        style: const TextStyle(
                                          fontFamily: GlmFonts.numbers,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      pl == null ? '' : value(pl),
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        fontFamily: GlmFonts.numbers,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
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

class _Pin extends CustomPainter {
  @override
  void paint(Canvas c, Size s) => c.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width / 2, s.height)
      ..close(),
    Paint()..color = const Color(0xFF55D6F2),
  );

  @override
  bool shouldRepaint(_Pin old) => false;
}

/// A little pitch in perspective, its grass, lines and edge.
class _MiniPitch extends CustomPainter {
  _MiniPitch(this.grass, this.dark);

  final Color grass, dark;

  @override
  void paint(Canvas c, Size s) {
    final top = Path()
      ..moveTo(s.width * .12, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width * .88, s.height * .82)
      ..lineTo(0, s.height * .82)
      ..close();
    c.drawPath(top.shift(Offset(0, s.height * .12)), Paint()..color = const Color(0xFF6E431B));
    c.drawPath(top, Paint()..shader = LinearGradient(colors: [Color.lerp(grass, Colors.white, .15)!, dark]).createShader(Offset.zero & s));
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    c.drawPath(top, line);
    c.drawLine(Offset(s.width * .56, 0), Offset(s.width * .44, s.height * .82), line);
    c.drawOval(Rect.fromCenter(center: Offset(s.width * .5, s.height * .41), width: s.width * .16, height: s.height * .4), line);
  }

  @override
  bool shouldRepaint(_MiniPitch old) => false;
}

/// The table's blue header, kept in sight while the list scrolls; a tap on a column sorts by it.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate(this.state);

  final _SquadScreenState state;

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final l = L.of(context);
    return Container(
      color: GlmStage.pill,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: _Cells(
        name: _Head(l.colName, _Col.name, state),
        age: _Head(l.colAge, _Col.age, state),
        nat: _Head(l.colNat, null, state),
        pos: _Head(l.colPos, _Col.pos, state),
        ovr: _Head(l.colOvr, _Col.ovr, state),
        pot: _Head(l.colPot, _Col.pot, state),
        fit: _Head(l.colFit, _Col.fit, state),
        value: _Head(l.colValue, _Col.value, state),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) => true;
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFEFF2F7),
    padding: const EdgeInsets.symmetric(vertical: 6),
    alignment: Alignment.center,
    child: Text(
      title,
      style: const TextStyle(color: Color(0xFF8C96A8), fontWeight: FontWeight.w700, fontSize: 16),
    ),
  );
}

/// The table's columns: the same widths in the header and each row.
class _Cells extends StatelessWidget {
  const _Cells({
    required this.name,
    required this.age,
    required this.nat,
    required this.pos,
    required this.ovr,
    required this.pot,
    required this.fit,
    required this.value,
  });

  final Widget name, age, nat, pos, ovr, pot, fit, value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final roomy = box.maxWidth >= 640;
      return Row(
        children: [
          Expanded(child: name),
          SizedBox(width: 48, child: age),
          if (roomy) SizedBox(width: 92, child: nat),
          SizedBox(width: 58, child: pos),
          SizedBox(width: 54, child: ovr),
          if (roomy) SizedBox(width: 54, child: pot),
          SizedBox(width: roomy ? 110 : 58, child: fit),
          if (roomy) SizedBox(width: 84, child: value),
        ],
      );
    },
  );
}

class _Head extends StatelessWidget {
  const _Head(this.label, this.col, this.state);

  final String label;
  final _Col? col;
  final _SquadScreenState state;

  @override
  Widget build(BuildContext context) {
    final on = col != null && state._sort == col;
    final text = Row(
      mainAxisAlignment: col == _Col.name ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: on ? const Color(0xFFFFE36E) : Colors.white),
          ),
        ),
        if (on) Icon(state._desc ? Icons.arrow_drop_down_rounded : Icons.arrow_drop_up_rounded, size: 20, color: const Color(0xFFFFE36E)),
      ],
    );
    return col == null ? text : InkWell(onTap: () => state._by(col!), child: text);
  }
}

/// One player on a white row: his shirt (blue for the eleven, grey otherwise) with the captain's band, his name, age,
/// nationality, position, rating in bold, potential, fitness and condition as two green bars, and his value.
class _Row extends StatelessWidget {
  const _Row(this.p, {required this.onTap, this.captain = false});

  final Player p;
  final VoidCallback onTap;
  final bool captain;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF14203A), soft = Color(0xFFA2ABBB);
    const num = TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 24, color: ink);
    final starter = p.role == 'starter', bench = p.role == 'bench';
    final c = context.palette;
    Widget bar(double v, Color color) => Container(
      width: 46,
      height: 20,
      decoration: BoxDecoration(color: const Color(0xFFE3E7EE), borderRadius: BorderRadius.circular(3)),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: v.clamp(.05, 1),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: BorderDirectional(
              bottom: const BorderSide(color: Color(0xFFEFF2F7)),
              start: BorderSide(color: starter ? const Color(0xFF6BE04A) : Colors.transparent, width: 5),
            ),
            gradient: starter
                ? LinearGradient(colors: [const Color(0xFF6BE04A).withValues(alpha: .10), Colors.white], stops: const [0, .35])
                : null,
          ),
          child: _Cells(
            name: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    KitShirt(
                      color: starter
                          ? GlmStage.pill
                          : bench
                          ? const Color(0xFF9AA4B5)
                          : const Color(0xFFD9DEE6),
                      trim: starter ? const Color(0xFFF3B71F) : Colors.white,
                      size: 38,
                    ),
                    if (captain)
                      Positioned(
                        bottom: -2,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(3)),
                          child: const Text(
                            'C',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: ink),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 24, color: ink),
                  ),
                ),
                if (!p.available) ...[
                  const SizedBox(width: 6),
                  Icon(
                    p.injured > 0 ? Icons.local_hospital_rounded : Icons.style_rounded,
                    size: 20,
                    color: p.injured > 0 ? c.live : c.cardYellow,
                  ),
                ],
              ],
            ),
            age: Text(
              '${p.age}',
              textAlign: TextAlign.center,
              style: num.copyWith(fontWeight: FontWeight.w600),
            ),
            nat: p.nationCode == null
                ? Text(
                    p.nationality ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: soft),
                  )
                : Center(
                    child: Tooltip(
                      message: p.nationality ?? '',
                      child: NationFlag(code: p.nationCode!, colors: p.nationColors, width: 44),
                    ),
                  ),
            pos: Center(child: PositionChip(p.position, p.line)),
            // [Sprint 46, the polish] The rating on a pill tinted by its level.
            ovr: Center(
              child: Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: ArcGauge.levelColor(context, p.overall).withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ArcGauge.levelColor(context, p.overall).withValues(alpha: .7), width: 1.5),
                ),
                child: Text('${p.overall}', textAlign: TextAlign.center, style: num),
              ),
            ),
            pot: Text(
              '${p.potential}',
              textAlign: TextAlign.center,
              style: num.copyWith(color: p.potential > p.overall ? c.success : soft, fontWeight: FontWeight.w600),
            ),
            fit: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  bar(p.fitness / 100, fitnessColor(p.fitness)),
                  const SizedBox(width: 6),
                  bar(p.available ? 1 : .15, p.available ? const Color(0xFF8BE04E) : c.live),
                ],
              ),
            ),
            value: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    money(context, p.value),
                    textDirection: TextDirection.ltr,
                    style: num.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 3),
                Image.asset('assets/brand/coin.png', width: 18, height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Money in short Western digits in every language (3.5M), as the game writes numbers (Sprint 30).
String money(BuildContext context, int v) => NumberFormat.compact(locale: 'en').format(v);

({Color bg, Color fg}) lineColor(String line) => switch (line) {
  'gk' => GlmLine.gk,
  'def' => GlmLine.def,
  'mid' => GlmLine.mid,
  _ => GlmLine.att,
};

Color fitnessColor(int f) => glmFitness.firstWhere((x) => f >= x.min, orElse: () => glmFitness.last).color;

class PlayerRow extends StatelessWidget {
  const PlayerRow(this.p, {super.key, this.onTap, this.selected = false, this.trailing});

  final Player p;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = context.palette;
    // [2026-11-06] A player as a game row: rating badge, position chip, the name, age and role, fitness as a bar.
    final starter = p.role == 'starter';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? c.gold.withValues(alpha: .16) : (starter ? Color.lerp(c.surface, c.pitchDark, .18) : c.surface),
        shape: GlmCut.shape(
          GlmCut.badge + 4,
          side: BorderSide(color: selected ? c.gold : Colors.white.withValues(alpha: context.glm.day ? 0 : .07)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: GlmCut.shape(GlmCut.badge + 4),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  RatingBadge(p.overall, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PositionChip(p.position, p.line),
                            const SizedBox(width: 8),
                            // Player names stay in English in every language (decision 2026-11-01).
                            Flexible(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                !p.available
                                    ? (p.injured > 0 ? '🩹 ${l.injuredFor(p.injured)}' : '🟥 ${l.suspendedFor(p.suspended)}')
                                    : '${l.age(p.age)} · ${starter
                                          ? l.starter
                                          : p.role == 'bench'
                                          ? l.bench
                                          : l.reserve}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.available ? (starter ? context.glm.successText : c.textMuted) : context.glm.liveText,
                                  fontSize: 12,
                                  fontWeight: starter ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${p.fitness}%',
                              style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 13, color: c.textMuted),
                            ),
                            const SizedBox(width: 6),
                            LevelBar(p.fitness / 100, color: fitnessColor(p.fitness)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A player's card: his numbers and each attribute as a bar.
Future<void> showPlayerCard(BuildContext context, Player p) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  backgroundColor: context.palette.panel,
  builder: (context) {
    final l = L.of(context);
    final c = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(p.name, textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: context.text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              [p.position, l.age(p.age), if (p.nationality != null) p.nationality!].join(' · '),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final (v, label) in [
                  ('${p.overall}', l.ratingWord),
                  ('${p.potential}', l.potentialWord),
                  ('${p.fitness}%', l.fitness),
                  (money(context, p.value), l.value),
                ])
                  Expanded(
                    child: FittedBox(fit: BoxFit.scaleDown, child: _big(context, v, label)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l.attributes, style: context.text.titleMedium),
            const SizedBox(height: 8),
            for (final a in p.attributes.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        a.key.toUpperCase(),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: c.textSoft, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: a.value / 100,
                          minHeight: 8,
                          backgroundColor: c.surfaceSunk,
                          color: a.value >= 80
                              ? c.success
                              : a.value >= 65
                              ? c.gold
                              : c.warning,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${a.value}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  },
);

Widget _big(BuildContext context, String v, String label) => Column(
  children: [
    Text(
      v,
      style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 26, fontWeight: FontWeight.w800, color: context.glm.goldText),
    ),
    Text(label, style: TextStyle(color: context.palette.textMuted, fontSize: 11)),
  ],
);
