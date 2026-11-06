import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/game_icons.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/kit.dart';
import '../../ui/widgets/motion.dart';
import 'squad_screen.dart';
import 'team_data.dart';
import '../leagues/shell.dart';

/// [Sprint 17 F1] The lineup on a pitch (the web's Lineup): the formation from the book, the eleven at their slots and
/// the bench under it. A tap on a player then on another swaps them (between the pitch, the bench and the rest), any
/// outfield player in any line as the web allows (Sprint 27, 88%), the keeper in goal. «Automatic» lets the game pick.
class LineupScreen extends ConsumerStatefulWidget {
  const LineupScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends ConsumerState<LineupScreen> {
  String? _formation;
  List<int>? _starters, _bench;
  int? _picked;
  bool _busy = false;

  void _load(TeamData t) {
    _formation ??= t.lineup.formation;
    _starters ??= [...t.lineup.starters];
    _bench ??= [...t.lineup.bench];
  }

  bool get _dirty {
    final t = ref.read(teamProvider(widget.leagueId)).value;
    return t != null && (_formation != t.lineup.formation || '$_starters' != '${t.lineup.starters}' || '$_bench' != '${t.lineup.bench}');
  }

  /// [Sprint 45 M4] A player dropped on another: the two swap (as two taps would).
  void _drop(int dragged, int onto) {
    if (dragged == onto) return;
    _picked = dragged;
    _tap(onto);
  }

  void _tap(int id) {
    HapticFeedback.selectionClick();
    if (_picked == null) return setState(() => _picked = id);
    if (_picked == id) return setState(() => _picked = null);
    setState(() {
      final a = _picked!, b = id;
      List<int>? where(int x) => _starters!.contains(x) ? _starters : _bench!.contains(x) ? _bench : null;
      final la = where(a), lb = where(b);
      if (la != null && lb != null) {
        final ia = la.indexOf(a), ib = lb.indexOf(b);
        la[ia] = b;
        lb[ib] = a;
      } else if (la != null) {
        la[la.indexOf(a)] = b; // a reserve comes in for a
      } else if (lb != null) {
        lb[lb.indexOf(b)] = a;
      }
      _picked = null;
    });
  }

  Future<void> _save({bool auto = false}) async {
    setState(() => _busy = true);
    final repo = ref.read(teamRepositoryProvider);
    try {
      final team = auto ? await repo.autoLineup(widget.leagueId) : await repo.saveLineup(widget.leagueId, _formation!, _starters!, _bench!);
      setState(() {
        _formation = team.lineup.formation;
        _starters = [...team.lineup.starters];
        _bench = [...team.lineup.bench];
      });
      ref.invalidate(teamProvider(widget.leagueId));
      if (mounted) showGlmToast(context, L.of(context).saved);
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.fields.values.firstOrNull ?? e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final team = ref.watch(teamProvider(widget.leagueId));
    final formations = ref.watch(formationsProvider).value ?? const <Formation>[];
    final save = GlmButton(label: l.save, block: true, loading: _busy, icon: const Icon(Icons.check_rounded), onPressed: _formation != null && _dirty ? _save : null);
    return Scaffold(
      appBar: GameBar(title: Text(l.lineup), actions: [
        // In landscape «automatic» is one of the pitch's round buttons.
        if (MediaQuery.sizeOf(context).width < 560) TextButton.icon(
          onPressed: _busy ? null : () => _save(auto: true),
          icon: Icon(Icons.auto_awesome_rounded, color: context.glm.goldText, size: 18),
          label: Text(l.autoLineup, style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800)),
        ),
      ]),
      body: GlmBackground(
        wide: true,
        child: AsyncView(
          value: team,
          onRetry: () => ref.invalidate(teamProvider(widget.leagueId)),
          data: (t) => LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth >= 560;
            _load(t);
            final slots = formations.where((f) => f.name == _formation).firstOrNull?.slots ?? t.lineup.slots;
            final others = t.players.where((p) => !_starters!.contains(p.id) && !_bench!.contains(p.id)).toList();
            final formation = GlmCard(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: Row(children: [
                if (wide) ...[const IconTile(Icons.grid_view_rounded, size: 34), const SizedBox(width: 10)],
                Flexible(child: Text(l.formation, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: formations.any((f) => f.name == _formation) ? _formation : null,
                    hint: Text(_formation ?? ''),
                    decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                    items: [for (final f in formations) DropdownMenuItem(value: f.name, child: Text(f.label, textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18)))],
                    onChanged: (v) => setState(() => _formation = v),
                  ),
                ),
              ]),
            );
            final hint = Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(children: [
                Icon(Icons.touch_app_rounded, size: 16, color: context.palette.textMuted),
                const SizedBox(width: 6),
                Expanded(child: Text(l.dragHint, style: TextStyle(color: context.palette.textMuted, fontSize: 12))),
              ]),
            );
            final pitch = _Pitch(slots: slots, starters: _starters!, team: t, picked: _picked, onTap: _tap, onDrop: _drop, horizontal: wide);
            final lists = [
              GameHeader(l.bench, icon: Icons.event_seat_rounded),
              for (final (i, id) in _bench!.indexed)
                if (t.byId(id) case final p?) FadeSlideIn(index: i, child: _DragRow(player: p, selected: _picked == id, onTap: () => _tap(id), onDrop: (d) => _drop(d, id))),
              if (others.isNotEmpty) ...[
                GameHeader(l.reserve, icon: Icons.groups_rounded),
                for (final p in others) _DragRow(player: p, selected: _picked == p.id, onTap: () => _tap(p.id), onDrop: (d) => _drop(d, p.id)),
              ],
            ];
            if (!wide) {
              return Column(children: [
                Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [formation, hint, const SizedBox(height: 10), pitch, ...lists])),
                SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: save)),
              ]);
            }
            // [Sprint 46, the owner's screenshots] Landscape as the manager games lay it out: the pitch in perspective on
            // the stadium filling the screen, each of the eleven a card at his place, the formation at the corner, the
            // tactics and specialists at the side, the bench's panel and «improve» below, and what the cards show
            // (fitness, age and nation, value) changed with a tap.
            return _Arena(
              slots: slots,
              starters: _starters!,
              others: [for (final id in _bench!) ?t.byId(id), ...others],
              team: t,
              picked: _picked,
              onTap: _tap,
              onDrop: _drop,
              formations: formations,
              formation: _formation,
              onFormation: (f) => setState(() => _formation = f),
              leagueId: widget.leagueId,
              save: _formation != null && _dirty ? _save : null,
              busy: _busy,
              auto: () => _save(auto: true),
            );
          }),
        ),
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({required this.slots, required this.starters, required this.team, required this.picked, required this.onTap, required this.onDrop, this.horizontal = false});

  /// A player dropped on a player of the eleven: (the one dragged, the one there).
  final void Function(int dragged, int onto) onDrop;

  final List<Slot> slots;
  final List<int> starters;
  final TeamData team;
  final int? picked;
  final ValueChanged<int> onTap;

  /// Lying across a landscape screen: my goal at the reading start, attacking toward its end.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final body = LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      const tokenW = 76.0, tokenH = 66.0;
      return Container(
        decoration: ShapeDecoration(
          shape: GlmCut.shape(GlmCut.card + 4, side: BorderSide(color: Colors.white.withValues(alpha: .12))),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.pitch, p.pitchDark]),
          shadows: [BoxShadow(color: p.shade.withValues(alpha: .45), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -10)],
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _Lines(Colors.white.withValues(alpha: .35), horizontal: horizontal))),
          for (var i = 0; i < slots.length && i < starters.length; i++)
            if (team.byId(starters[i]) case final pl?)
              Builder(builder: (context) {
                // x runs from my goal forward, y across (0..740 and 0..680 in the book).
                final fwd = (slots[i].x / 740).clamp(0.0, 1.0), across = (slots[i].y / 680).clamp(0.0, 1.0);
                final left = horizontal ? (rtl ? 1 - fwd : fwd) * (w - tokenW) : across * (w - tokenW);
                final top = horizontal ? across * (h - tokenH) : (1 - fwd) * (h - tokenH);
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: top,
                  width: tokenW,
                  child: _Token(player: pl, line: slots[i].line, picked: picked == pl.id, onTap: () => onTap(pl.id), onDrop: (d) => onDrop(d, pl.id)),
                );
              }),
        ]),
      );
    });
    return horizontal ? body : AspectRatio(aspectRatio: 0.78, child: body);
  }
}

/// A player on the pitch: his shirt in his line's colour with his rating on it, and his surname under it.
class _Token extends StatelessWidget {
  const _Token({required this.player, required this.line, required this.picked, required this.onTap, required this.onDrop});

  final Player player;
  final String line;
  final bool picked;
  final VoidCallback onTap;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) {
    final c = lineColor(line);
    Widget shirt({bool lit = false, bool ghost = false}) => Opacity(
          opacity: ghost ? .35 : 1,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            KitShirt(color: picked || lit ? context.palette.gold : c.bg, trim: Colors.white, label: '${player.overall}', size: 44, picked: picked || lit),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(5)),
              child: Text(player.name.split(' ').last, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
            ),
          ]),
        );
    // [Sprint 45 M4] Dragged straight away on the pitch; a player dropped on him swaps with him, his shirt lit gold.
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != player.id,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, over, _) => Draggable<int>(
        data: player.id,
        feedback: Material(type: MaterialType.transparency, child: Transform.scale(scale: 1.2, child: shirt(lit: true))),
        childWhenDragging: shirt(ghost: true),
        onDragStarted: HapticFeedback.selectionClick,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(scale: picked || over.isNotEmpty ? 1.15 : 1, duration: const Duration(milliseconds: 160), child: shirt(lit: over.isNotEmpty)),
        ),
      ),
    );
  }
}

/// [Sprint 45 M4] A bench or reserve player in the list: held a moment, he lifts and can be dropped on the pitch or on
/// another; a player dropped on him swaps with him.
class _DragRow extends StatelessWidget {
  const _DragRow({required this.player, required this.selected, required this.onTap, required this.onDrop});

  final Player player;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != player.id,
        onAcceptWithDetails: (d) => onDrop(d.data),
        builder: (context, over, _) => LongPressDraggable<int>(
          data: player.id,
          onDragStarted: HapticFeedback.mediumImpact,
          feedback: Material(
            type: MaterialType.transparency,
            child: Transform.scale(scale: 1.1, child: KitShirt(color: context.palette.gold, trim: Colors.white, label: '${player.overall}', size: 52, picked: true)),
          ),
          childWhenDragging: Opacity(opacity: .4, child: PlayerRow(player)),
          child: PlayerRow(player, selected: selected || over.isNotEmpty, onTap: onTap),
        ),
      );
}

class _Lines extends CustomPainter {
  _Lines(this.color, {this.horizontal = false});

  final Color color;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    // The mowing stripes, then the markings; drawn upright and turned a quarter for a pitch lying across.
    if (horizontal) {
      canvas.translate(size.width, 0);
      canvas.rotate(1.5707963267948966);
    }
    final s = horizontal ? Size(size.height, size.width) : size;
    final stripe = Paint()..color = Colors.black.withValues(alpha: .07);
    for (var i = 0; i < 10; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, s.height * i / 10, s.width, s.height / 10), stripe);
    }
    final pen = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6, 6, s.width - 12, s.height - 12), const Radius.circular(12)), pen);
    canvas.drawLine(Offset(6, s.height / 2), Offset(s.width - 6, s.height / 2), pen);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * .14, pen);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), 3, Paint()..color = color);
    for (final top in [true, false]) {
      final y = top ? 6.0 : s.height - 6;
      final d = top ? 1 : -1;
      canvas.drawRect(Rect.fromPoints(Offset(s.width * .22, y), Offset(s.width * .78, y + d * s.height * .15)), pen);
      canvas.drawRect(Rect.fromPoints(Offset(s.width * .38, y), Offset(s.width * .62, y + d * s.height * .06)), pen);
      canvas.drawArc(Rect.fromCircle(center: Offset(s.width / 2, y + d * s.height * .15), radius: s.width * .09), top ? 0 : 3.141592653589793, 3.141592653589793, false, pen);
    }
  }

  @override
  bool shouldRepaint(_Lines old) => old.color != color || old.horizontal != horizontal;
}

enum _Mode { fitness, age, value }

/// [Sprint 46] The lineup on the stadium, landscape.
class _Arena extends StatefulWidget {
  const _Arena({required this.slots, required this.starters, required this.others, required this.team, required this.picked, required this.onTap,
      required this.onDrop, required this.formations, required this.formation, required this.onFormation, required this.leagueId, required this.save,
      required this.busy, required this.auto});

  final List<Slot> slots;
  final List<int> starters;
  final List<Player> others;
  final TeamData team;
  final int? picked;
  final ValueChanged<int> onTap;
  final void Function(int dragged, int onto) onDrop;
  final List<Formation> formations;
  final String? formation;
  final ValueChanged<String> onFormation;
  final int leagueId;
  final VoidCallback? save;
  final bool busy;
  final VoidCallback auto;

  @override
  State<_Arena> createState() => _ArenaState();
}

class _ArenaState extends State<_Arena> {
  _Mode _mode = _Mode.fitness;
  bool _bench = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      // The pitch's trapezoid: its far line high and narrow, its near line low and wide.
      final top = h * .05, bottom = h * .98, farW = w * .56, nearW = w * 1.02;
      Offset place(double across, double fwd) {
        final y = lerpDouble(bottom - h * .06, top + h * .16, fwd)!;
        final k = (y - top) / (bottom - top);
        final width = lerpDouble(farW, nearW, k)!;
        return Offset(w / 2 + (across - .5) * width * .86, y);
      }

      const cardW = 150.0, cardH = 70.0;
      // Drawn at 150 × 70 and scaled to the room: smaller toward the far line, and with the screen's width.
      final room = (w / 1100).clamp(.55, 1.0);
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final cards = <(double, Widget)>[];
      for (var i = 0; i < widget.slots.length && i < widget.starters.length; i++) {
        final pl = widget.team.byId(widget.starters[i]);
        if (pl == null) continue;
        final s = widget.slots[i];
        var across = (s.y / 680).clamp(0.0, 1.0);
        if (rtl) across = 1 - across;
        final at = place(across, (s.x / 740).clamp(0.0, 1.0));
        final k = lerpDouble(.8, 1.0, ((at.dy - top) / (bottom - top)).clamp(0.0, 1.0))! * room;
        cards.add((at.dy, Positioned(
          left: at.dx - cardW * k / 2,
          top: at.dy - cardH * k,
          width: cardW * k,
          height: cardH * k,
          child: _Drag(
            id: pl.id,
            onDrop: (d) => widget.onDrop(d, pl.id),
            child: GestureDetector(onTap: () => widget.onTap(pl.id), child: FittedBox(child: SizedBox(width: cardW, height: cardH, child: _Card(pl, mode: _mode, picked: widget.picked == pl.id, starter: true)))),
          ),
        )));
      }
      cards.sort((a, b) => a.$1.compareTo(b.$1));
      Widget round(Widget icon, String tip, VoidCallback onTap) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Tooltip(
              message: tip,
              child: Material(
                shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
                color: GlmArena.navyLight,
                elevation: 4,
                child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox.square(dimension: 56, child: Center(child: icon))),
              ),
            ),
          );
      Widget labelled(Widget icon, String label, VoidCallback onTap) => GestureDetector(
            onTap: onTap,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56,
                height: 44,
                decoration: const BoxDecoration(color: GlmArena.navy, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: Center(child: icon),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: ShapeDecoration(shape: GlmCut.shape(8, side: const BorderSide(color: GlmArena.navyEdge)), color: GlmArena.navy),
                child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ]),
          );
      final modeIcon = switch (_mode) { _Mode.fitness => Icons.fitness_center_rounded, _Mode.age => Icons.cake_rounded, _Mode.value => Icons.payments_rounded };
      final modeLabel = switch (_mode) { _Mode.fitness => l.modeFitness, _Mode.age => l.modeAge, _Mode.value => l.modeValue };
      return Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _ArenaPitch(grass: p.pitch, dark: p.pitchDark, top: top, bottom: bottom, farW: farW, nearW: nearW))),
        for (final c in cards) c.$2,
        // The tactics and the specialists at the side.
        PositionedDirectional(
          end: 14,
          top: 10,
          child: Column(children: [
            round(const GameIcon(GameGlyph.tactics, size: 34), l.tactics, () => context.push('/leagues/${widget.leagueId}/tactics')),
            round(const GameIcon(GameGlyph.specialists, size: 34), l.specialists, () => context.push('/leagues/${widget.leagueId}/specialists')),
            round(const Icon(Icons.auto_awesome_rounded, color: Colors.white), l.autoLineup, widget.auto),
          ]),
        ),
        // The formation at the other corner.
        PositionedDirectional(
          start: 14,
          top: 10,
          child: PopupMenuButton<String>(
            onSelected: widget.onFormation,
            itemBuilder: (_) => [for (final f in widget.formations) PopupMenuItem(value: f.name, child: Text(f.label, textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18)))],
            child: labelled(const GameIcon(GameGlyph.lineup, size: 30), widget.formation ?? '', () {}),
          ),
        ),
        // The bench's panel and «save» below.
        PositionedDirectional(
          end: 14,
          bottom: 10,
          child: Row(children: [
            labelled(const Icon(Icons.event_seat_rounded, color: Colors.white, size: 26), l.benchPanel, () => setState(() => _bench = !_bench)),
            const SizedBox(width: 12),
            if (widget.save != null || widget.busy) SizedBox(width: 150, child: GlmButton(label: l.save, loading: widget.busy, icon: const Icon(Icons.check_rounded), onPressed: widget.save)),
          ]),
        ),
        PositionedDirectional(
          start: 14,
          bottom: 10,
          child: labelled(Icon(modeIcon, color: Colors.white, size: 26), modeLabel, () => setState(() => _mode = _Mode.values[(_mode.index + 1) % _Mode.values.length])),
        ),
        if (_bench)
          Positioned(
            left: w * .06,
            right: w * .06,
            bottom: 12,
            height: h * .5,
            child: _BenchPanel(others: widget.others, mode: _mode, picked: widget.picked, onTap: widget.onTap, onDrop: widget.onDrop, close: () => setState(() => _bench = false)),
          ),
      ]);
    });
  }
}

/// The pitch in perspective on the stadium: the stands, the grass with its stripes, its lines and the near box.
class _ArenaPitch extends CustomPainter {
  _ArenaPitch({required this.grass, required this.dark, required this.top, required this.bottom, required this.farW, required this.nearW});

  final Color grass, dark;
  final double top, bottom, farW, nearW;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmArena.blueDeep, GlmArena.navy]).createShader(r));
    // The crowd: dots in the stands around the pitch.
    final rnd = math.Random(4);
    final dot = Paint();
    for (var i = 0; i < 1400; i++) {
      final x = rnd.nextDouble() * s.width, y = rnd.nextDouble() * s.height;
      dot.color = Colors.white.withValues(alpha: .04 + rnd.nextDouble() * .08);
      c.drawCircle(Offset(x, y), 1.4, dot);
    }
    Offset at(double u, double v) {
      final y = lerpDouble(top, bottom, v)!;
      final width = lerpDouble(farW, nearW, v)!;
      return Offset(s.width / 2 + (u - .5) * width, y);
    }

    final field = Path()..moveTo(at(0, 0).dx, at(0, 0).dy)..lineTo(at(1, 0).dx, at(1, 0).dy)..lineTo(at(1, 1).dx, at(1, 1).dy)..lineTo(at(0, 1).dx, at(0, 1).dy)..close();
    c.drawPath(field.shift(const Offset(0, 8)), Paint()..color = Colors.black.withValues(alpha: .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    c.drawPath(field, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [dark, grass]).createShader(r));
    c.save();
    c.clipPath(field);
    final stripe = Paint()..color = Colors.white.withValues(alpha: .05);
    for (var i = 0; i < 12; i += 2) {
      final v0 = i / 12, v1 = (i + 1) / 12;
      c.drawPath(Path()..moveTo(at(0, v0).dx, at(0, v0).dy)..lineTo(at(1, v0).dx, at(1, v0).dy)..lineTo(at(1, v1).dx, at(1, v1).dy)..lineTo(at(0, v1).dx, at(0, v1).dy)..close(), stripe);
    }
    c.restore();
    final line = Paint()..color = Colors.white.withValues(alpha: .85)..style = PaintingStyle.stroke..strokeWidth = 2.2;
    final inset = Path()..moveTo(at(.03, .02).dx, at(.03, .02).dy)..lineTo(at(.97, .02).dx, at(.97, .02).dy)..lineTo(at(.97, .97).dx, at(.97, .97).dy)..lineTo(at(.03, .97).dx, at(.03, .97).dy)..close();
    c.drawPath(inset, line);
    c.drawLine(at(.03, .4), at(.97, .4), line);
    final mid = at(.5, .4);
    c.drawOval(Rect.fromCenter(center: mid, width: lerpDouble(farW, nearW, .4)! * .2, height: s.height * .14), line);
    // The near box and the six-yard box.
    for (final (w, d) in [(.5, .2), (.24, .07)]) {
      c.drawPath(Path()..moveTo(at(.5 - w / 2, .97).dx, at(.5 - w / 2, .97).dy)..lineTo(at(.5 - w / 2, .97 - d).dx, at(.5 - w / 2, .97 - d).dy)..lineTo(at(.5 + w / 2, .97 - d).dx, at(.5 + w / 2, .97 - d).dy)..lineTo(at(.5 + w / 2, .97).dx, at(.5 + w / 2, .97).dy), line);
    }
  }

  @override
  bool shouldRepaint(_ArenaPitch old) => old.farW != farW || old.top != top;
}

/// A player's card on the pitch or the bench: navy lit from the top, a green edge for the eleven (gold when picked).
/// What it shows follows the mode: his rating, his line's letters and fitness and availability as two bars; his age,
/// nation and potential; his value.
class _Card extends StatelessWidget {
  const _Card(this.p, {required this.mode, this.picked = false, this.starter = false});

  final Player p;
  final _Mode mode;
  final bool picked, starter;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final edge = picked ? c.gold : starter ? const Color(0xFF6BE04A) : GlmArena.navyEdge;
    final big = const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white, height: 1);
    final small = const TextStyle(color: Color(0xFFB9C7E3), fontWeight: FontWeight.w700, fontSize: 11, height: 1);
    Widget bar(double v, Color color) => Container(
          width: 34,
          height: 9,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .4), borderRadius: BorderRadius.circular(2)),
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(widthFactor: v.clamp(.05, 1), heightFactor: 1, child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
        );
    final body = switch (mode) {
      _Mode.fitness => Row(children: [
          Text('${p.overall}', style: big),
          const SizedBox(width: 6),
          Expanded(child: Center(child: Icon(Icons.person_rounded, size: 34, color: Colors.white.withValues(alpha: .25)))),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [bar(p.fitness / 100, fitnessColor(p.fitness)), const SizedBox(height: 5), bar(p.available ? 1 : .15, p.available ? const Color(0xFF6BE04A) : c.live)]),
        ]),
      _Mode.age => Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(mainAxisSize: MainAxisSize.min, children: [Text(L.of(context).modeAge, style: small), const SizedBox(height: 3), Text('${p.age}', style: big)]),
          Column(mainAxisSize: MainAxisSize.min, children: [Text(L.of(context).colPot, style: small), const SizedBox(height: 3), Text('${p.potential}', style: big)]),
          if (p.nationCode != null) NationFlag(code: p.nationCode!, colors: p.nationColors, width: 34),
        ]),
      _Mode.value => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset('assets/brand/coin.png', width: 18, height: 18),
          const SizedBox(width: 6),
          Text(money(context, p.value), textDirection: TextDirection.ltr, style: big),
        ]),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: GlmCut.shape(12, side: BorderSide(color: edge, width: 3)),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmArena.navyLight, GlmArena.navy]),
        shadows: [BoxShadow(color: (starter ? const Color(0xFF6BE04A) : Colors.black).withValues(alpha: .35), blurRadius: 10, spreadRadius: -2)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 4),
        child: Column(children: [
          Row(children: [
            PositionChip(p.position, p.line),
            const Spacer(),
            if (!p.available) Icon(p.injured > 0 ? Icons.local_hospital_rounded : Icons.style_rounded, size: 14, color: c.live),
          ]),
          Expanded(child: body),
          Text(p.name.split(' ').last.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white, height: 1.05)),
        ]),
      ),
    );
  }
}

/// A card that can be dragged and dropped on another: the two swap.
class _Drag extends StatelessWidget {
  const _Drag({required this.id, required this.onDrop, required this.child});

  final int id;
  final ValueChanged<int> onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != id,
        onAcceptWithDetails: (d) => onDrop(d.data),
        builder: (context, over, _) => Draggable<int>(
          data: id,
          onDragStarted: HapticFeedback.selectionClick,
          feedback: Material(type: MaterialType.transparency, child: Opacity(opacity: .9, child: SizedBox(width: 150, height: 70, child: child))),
          childWhenDragging: Opacity(opacity: .35, child: child),
          child: AnimatedScale(scale: over.isNotEmpty ? 1.08 : 1, duration: const Duration(milliseconds: 140), child: child),
        ),
      );
}

/// The bench and the rest by line, in a panel over the pitch's near half; a card dragged from it onto one of the eleven
/// takes his place (or a tap on each).
class _BenchPanel extends StatelessWidget {
  const _BenchPanel({required this.others, required this.mode, required this.picked, required this.onTap, required this.onDrop, required this.close});

  final List<Player> others;
  final _Mode mode;
  final int? picked;
  final ValueChanged<int> onTap;
  final void Function(int dragged, int onto) onDrop;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final lines = [('att', l.groupAtt), ('mid', l.groupMid), ('def', l.groupDef), ('gk', l.groupGk)];
    return Material(
      shape: GlmCut.shape(16, side: const BorderSide(color: GlmArena.blueLight, width: 3)),
      color: GlmArena.navy.withValues(alpha: .96),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (line, title) in lines)
              Expanded(
                child: Column(children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView(padding: const EdgeInsets.symmetric(horizontal: 6), children: [
                      for (final p in others.where((p) => p.line == line))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            height: 66,
                            child: _Drag(id: p.id, onDrop: (d) => onDrop(d, p.id), child: GestureDetector(onTap: () => onTap(p.id), child: _Card(p, mode: mode, picked: picked == p.id))),
                          ),
                        ),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
        PositionedDirectional(top: 2, end: 2, child: IconButton(onPressed: close, icon: const Icon(Icons.close_rounded, color: Colors.white))),
      ]),
    );
  }
}
