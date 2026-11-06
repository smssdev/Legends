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
import 'team_data.dart';

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
    final xs = [for (final p in team.players) if (_line == null || p.line == _line) p];
    int cmp(Player a, Player b) => switch (_sort) {
          _Col.pos => (_lineOrder[a.line] ?? 9).compareTo(_lineOrder[b.line] ?? 9) != 0 ? (_lineOrder[a.line] ?? 9).compareTo(_lineOrder[b.line] ?? 9) : b.overall.compareTo(a.overall),
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
    final c = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(l.squad)),
      body: GlmBackground(
        wide: true,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(teamProvider(widget.leagueId).future),
          child: AsyncView(
            value: ref.watch(teamProvider(widget.leagueId)),
            onRetry: () => ref.invalidate(teamProvider(widget.leagueId)),
            data: (team) {
              final rows = _rows(team);
              final lines = {null: l.filterAll, 'gk': l.lineGk, 'def': l.lineDef, 'mid': l.lineMid, 'att': l.lineAtt};
              return Column(children: [
                // The squad in numbers, and the lines to filter by.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(children: [
                    _Chip(icon: Icons.groups_rounded, text: '${team.players.length}'),
                    const SizedBox(width: 6),
                    _Chip(icon: Icons.payments_rounded, text: money(context, team.squadValue)),
                    const SizedBox(width: 6),
                    _Chip(icon: Icons.mood_rounded, text: l.morale(team.morale)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final e in lines.entries)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(start: 6),
                              child: ChoiceChip(
                                label: Text(e.value),
                                selected: _line == e.key,
                                showCheckmark: false,
                                selectedColor: e.key == null ? c.gold.withValues(alpha: .28) : lineColor(e.key!).bg,
                                labelStyle: TextStyle(fontWeight: FontWeight.w800, color: _line == e.key && e.key != null ? lineColor(e.key!).fg : c.text),
                                onSelected: (_) => setState(() => _line = e.key),
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ]),
                ),
                // The table: its header sorts.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    decoration: ShapeDecoration(shape: GlmCut.shape(GlmCut.badge), color: Colors.black.withValues(alpha: .28)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: _Cells(
                      pos: _Head(l.colPos, _Col.pos, this),
                      name: _Head(l.colName, _Col.name, this),
                      age: _Head(l.colAge, _Col.age, this),
                      ovr: _Head(l.colOvr, _Col.ovr, this),
                      pot: _Head(l.colPot, _Col.pot, this),
                      fit: _Head(l.colFit, _Col.fit, this),
                      value: _Head(l.colValue, _Col.value, this),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: rows.length,
                    itemBuilder: (context, i) => FadeSlideIn(index: i, child: _Row(rows[i], odd: i.isOdd, onTap: () => showPlayerCard(context, rows[i]))),
                  ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: ShapeDecoration(shape: GlmCut.shape(8), color: Colors.black.withValues(alpha: .25)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: context.palette.gold),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      );
}

/// The table's columns: the same widths in the header and each row.
class _Cells extends StatelessWidget {
  const _Cells({required this.pos, required this.name, required this.age, required this.ovr, required this.pot, required this.fit, required this.value});

  final Widget pos, name, age, ovr, pot, fit, value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final roomy = box.maxWidth >= 520;
        return Row(children: [
          SizedBox(width: 50, child: pos),
          const SizedBox(width: 8),
          Expanded(child: name),
          SizedBox(width: 40, child: age),
          SizedBox(width: 50, child: ovr),
          if (roomy) SizedBox(width: 50, child: pot),
          SizedBox(width: roomy ? 78 : 56, child: fit),
          if (roomy) SizedBox(width: 64, child: value),
        ]);
      });
}

class _Head extends StatelessWidget {
  const _Head(this.label, this.col, this.state);

  final String label;
  final _Col col;
  final _SquadScreenState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = state._sort == col;
    return InkWell(
      onTap: () => state._by(col),
      child: Row(mainAxisAlignment: col == _Col.name ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: on ? context.glm.goldText : p.textMuted))),
        if (on) Icon(state._desc ? Icons.arrow_drop_down_rounded : Icons.arrow_drop_up_rounded, size: 18, color: p.gold),
      ]),
    );
  }
}

/// One player in the table: his line's colour down its edge, a starter's green tint, the unavailable marked.
class _Row extends StatelessWidget {
  const _Row(this.p, {required this.odd, required this.onTap});

  final Player p;
  final bool odd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final num = TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 17, color: c.text);
    final starter = p.role == 'starter';
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        shape: GlmCut.shape(GlmCut.chip + 2),
        clipBehavior: Clip.antiAlias,
        color: starter ? Color.lerp(c.surface, c.pitchDark, .22) : (odd ? c.surface : Color.lerp(c.surface, c.surfaceRaised, .35)),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: lineColor(p.line).bg, width: 4))),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: _Cells(
              pos: Center(child: PositionChip(p.position, p.line)),
              name: Row(children: [
                Flexible(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                if (!p.available) ...[
                  const SizedBox(width: 6),
                  Icon(p.injured > 0 ? Icons.healing_rounded : Icons.block_rounded, size: 16, color: c.danger),
                ],
                if (starter) ...[const SizedBox(width: 6), Icon(Icons.check_circle_rounded, size: 14, color: c.success)],
              ]),
              age: Text('${p.age}', textAlign: TextAlign.center, style: num.copyWith(fontSize: 15, color: c.textSoft)),
              ovr: Center(child: RatingBadge(p.overall, size: 32)),
              pot: Text('${p.potential}', textAlign: TextAlign.center, style: num.copyWith(color: p.potential > p.overall ? context.glm.successText : c.textSoft)),
              fit: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: LevelBar(p.fitness / 100, color: fitnessColor(p.fitness), width: 34, height: 6)),
                const SizedBox(width: 4),
                Text('${p.fitness}', style: num.copyWith(fontSize: 13, color: c.textSoft)),
              ]),
              value: Text(money(context, p.value), textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: num.copyWith(fontSize: 14, color: context.glm.goldText)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Money in short Western digits in every language (3.5M), as the game writes numbers (Sprint 30).
String money(BuildContext context, int v) => NumberFormat.compact(locale: 'en').format(v);

({Color bg, Color fg}) lineColor(String line) => switch (line) { 'gk' => GlmLine.gk, 'def' => GlmLine.def, 'mid' => GlmLine.mid, _ => GlmLine.att };

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
        shape: GlmCut.shape(GlmCut.badge + 4, side: BorderSide(color: selected ? c.gold : Colors.white.withValues(alpha: context.glm.day ? 0 : .07))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: GlmCut.shape(GlmCut.badge + 4),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children: [
                RatingBadge(p.overall, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      PositionChip(p.position, p.line),
                      const SizedBox(width: 8),
                      // Player names stay in English in every language (decision 2026-11-01).
                      Flexible(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                        child: Text(
                          !p.available ? (p.injured > 0 ? '🩹 ${l.injuredFor(p.injured)}' : '🟥 ${l.suspendedFor(p.suspended)}') : '${l.age(p.age)} · ${starter ? l.starter : p.role == 'bench' ? l.bench : l.reserve}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.available ? (starter ? context.glm.successText : c.textMuted) : context.glm.liveText, fontSize: 12, fontWeight: starter ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                      Text('${p.fitness}%', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 13, color: c.textMuted)),
                      const SizedBox(width: 6),
                      LevelBar(p.fitness / 100, color: fitnessColor(p.fitness)),
                    ]),
                  ]),
                ),
                ?trailing,
              ]),
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
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(p.name, textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text([p.position, l.age(p.age), if (p.nationality != null) p.nationality!].join(' · '), textAlign: TextAlign.center, style: TextStyle(color: c.textMuted)),
              const SizedBox(height: 14),
              Row(children: [
                for (final (v, label) in [('${p.overall}', l.ratingWord), ('${p.potential}', l.potentialWord), ('${p.fitness}%', l.fitness), (money(context, p.value), l.value)])
                  Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: _big(context, v, label))),
              ]),
              const SizedBox(height: 16),
              Text(l.attributes, style: context.text.titleMedium),
              const SizedBox(height: 8),
              for (final a in p.attributes.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(width: 90, child: Text(a.key.toUpperCase(), textDirection: TextDirection.ltr, style: TextStyle(color: c.textSoft, fontWeight: FontWeight.w700, fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: a.value / 100, minHeight: 8, backgroundColor: c.surfaceSunk, color: a.value >= 80 ? c.success : a.value >= 65 ? c.gold : c.warning),
                      ),
                    ),
                    SizedBox(width: 34, child: Text('${a.value}', textAlign: TextAlign.end, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16))),
                  ]),
                ),
            ]),
          ),
        );
      },
    );

Widget _big(BuildContext context, String v, String label) => Column(children: [
      Text(v, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 26, fontWeight: FontWeight.w800, color: context.glm.goldText)),
      Text(label, style: TextStyle(color: context.palette.textMuted, fontSize: 11)),
    ]);
