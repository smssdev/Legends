import 'dart:async';

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import 'lineup_controller.dart';
import 'team_data.dart';
import '../leagues/shell.dart';

part 'lineup_screen_drag_row.dart';
part 'lineup_screen_arena_pitch.dart';

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
  // [Sprint 59 F5] The draft lives in LineupEditor; the screen keeps only which player is picked.
  int? _picked;
  LineupDraft? _draft;

  LineupEditor get _editor => ref.read(lineupEditorProvider(widget.leagueId).notifier);
  TeamData? get _team => ref.read(teamProvider(widget.leagueId)).value;
  String? get _formation => _draft?.formation;
  List<int>? get _starters => _draft?.starters;
  List<int>? get _bench => _draft?.bench;
  bool get _busy => _draft?.busy ?? false;
  bool get _dirty {
    final t = _team;
    return t != null && _draft != null && _draft!.changedFrom(t.lineup);
  }

  /// [2026-11-09] The places on the pitch: the saved formation at the places the coach dragged it to (on the site), or
  /// another formation at its own.
  List<Slot> _slots(TeamData t, List<Formation> formations) => _formation == t.lineup.formation
      ? t.lineup.slots
      : formations.where((f) => f.name == _formation).firstOrNull?.slots ?? t.lineup.slots;

  void _pickFormation(String? f) {
    final t = _team;
    if (f != null && t != null) _editor.formation(f, t.lineup);
  }

  /// [Sprint 45 M4] A player dropped on another: the two swap (as two taps would).
  void _drop(int dragged, int onto) {
    if (dragged == onto) return;
    _picked = dragged;
    _tap(onto);
  }

  void _tap(int id) {
    unawaited(HapticFeedback.selectionClick());
    if (_picked == null) return setState(() => _picked = id);
    if (_picked == id) return setState(() => _picked = null);
    final t = _team;
    final a = _picked!;
    setState(() => _picked = null);
    if (t == null) return;
    final slots = _slots(t, ref.read(formationsProvider).value ?? const []);
    final done = _editor.swap(a, id, t.lineup, slots, (x) => t.players.where((p) => p.id == x).firstOrNull?.line);
    if (!done) showGlmToast(context, L.of(context).keeperSlotOnly, error: true);
  }

  Future<void> _save({bool auto = false}) async {
    final t = _team;
    if (t == null) return;
    // [2026-11-09] The ten outfield places go with the lineup, as the site sends them: without them the server would
    // forget the places the coach dragged his players to on the site.
    final positions = [
      for (final s in _slots(t, ref.read(formationsProvider).value ?? const <Formation>[]).skip(1)) [s.x, s.y],
    ];
    final e = await _editor.save(t.lineup, auto: auto, positions: positions.length == 10 ? positions : null);
    if (!mounted) return;
    if (e == null) {
      showGlmToast(context, L.of(context).saved);
    } else {
      showGlmToast(context, e.fields.values.firstOrNull ?? e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final team = ref.watch(teamProvider(widget.leagueId));
    final edited = ref.watch(lineupEditorProvider(widget.leagueId));
    _draft = edited ?? (team.value == null ? null : LineupDraft.of(team.value!.lineup));
    final formations = ref.watch(formationsProvider).value ?? const <Formation>[];
    final save = GlmButton(
      label: l.save,
      block: true,
      loading: _busy,
      icon: const Icon(Icons.check_rounded),
      onPressed: _formation != null && _dirty ? _save : null,
    );
    return Scaffold(
      appBar: GameBar(
        title: Text(l.lineup),
        actions: [
          // In landscape «automatic» is one of the pitch's round buttons.
          if (MediaQuery.sizeOf(context).width < 560)
            TextButton.icon(
              onPressed: _busy ? null : () => _save(auto: true),
              icon: Icon(Icons.auto_awesome_rounded, color: context.glm.goldText, size: 18),
              label: Text(
                l.autoLineup,
                style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      body: GlmBackground(
        wide: true,
        child: AsyncView(
          value: team,
          onRetry: () => ref.invalidate(teamProvider(widget.leagueId)),
          data: (t) => LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 560;
              final slots = _slots(t, formations);
              final others = t.players.where((p) => !_starters!.contains(p.id) && !_bench!.contains(p.id)).toList();
              final formation = GlmCard(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Row(
                  children: [
                    if (wide) ...[const IconTile(Icons.grid_view_rounded, size: 34), const SizedBox(width: 10)],
                    Flexible(
                      child: Text(l.formation, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: formations.any((f) => f.name == _formation) ? _formation : null,
                        hint: Text(_formation ?? ''),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        items: [
                          for (final f in formations)
                            DropdownMenuItem(
                              value: f.name,
                              child: Text(
                                f.label,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                            ),
                        ],
                        onChanged: _pickFormation,
                      ),
                    ),
                  ],
                ),
              );
              final hint = Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 16, color: context.palette.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(l.dragHint, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
                    ),
                  ],
                ),
              );
              final pitch = _Pitch(
                slots: slots,
                starters: _starters!,
                team: t,
                picked: _picked,
                onTap: _tap,
                onDrop: _drop,
                horizontal: wide,
              );
              final lists = [
                GameHeader(l.bench, icon: Icons.event_seat_rounded),
                for (final (i, id) in _bench!.indexed)
                  if (t.byId(id) case final p?)
                    FadeSlideIn(
                      index: i,
                      child: _DragRow(player: p, selected: _picked == id, onTap: () => _tap(id), onDrop: (d) => _drop(d, id)),
                    ),
                if (others.isNotEmpty) ...[
                  GameHeader(l.reserve, icon: Icons.groups_rounded),
                  for (final p in others)
                    _DragRow(player: p, selected: _picked == p.id, onTap: () => _tap(p.id), onDrop: (d) => _drop(d, p.id)),
                ],
              ];
              if (!wide) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [formation, hint, const SizedBox(height: 10), pitch, ...lists],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(padding: const EdgeInsets.all(12), child: save),
                    ),
                  ],
                );
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
                onFormation: _pickFormation,
                leagueId: widget.leagueId,
                save: _formation != null && _dirty ? _save : null,
                busy: _busy,
                auto: () => _save(auto: true),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({
    required this.slots,
    required this.starters,
    required this.team,
    required this.picked,
    required this.onTap,
    required this.onDrop,
    this.horizontal = false,
  });

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
    final body = LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        const tokenW = 76.0, tokenH = 66.0;
        return Container(
          decoration: ShapeDecoration(
            shape: GlmCut.shape(GlmCut.card + 4, side: BorderSide(color: Colors.white.withValues(alpha: .12))),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.pitch, p.pitchDark]),
            shadows: [BoxShadow(color: p.shade.withValues(alpha: .45), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -10)],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _Lines(Colors.white.withValues(alpha: .35), horizontal: horizontal)),
              ),
              for (var i = 0; i < slots.length && i < starters.length; i++)
                if (team.byId(starters[i]) case final pl?)
                  Builder(
                    builder: (context) {
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
                        child: _Token(
                          player: pl,
                          line: slots[i].line,
                          picked: picked == pl.id,
                          onTap: () => onTap(pl.id),
                          onDrop: (d) => onDrop(d, pl.id),
                        ),
                      );
                    },
                  ),
            ],
          ),
        );
      },
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KitShirt(
            color: picked || lit ? context.palette.gold : c.bg,
            trim: Colors.white,
            label: '${player.overall}',
            size: 44,
            picked: picked || lit,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(5)),
            child: Text(
              player.name.split(' ').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
    // [Sprint 45 M4] Dragged straight away on the pitch; a player dropped on him swaps with him, his shirt lit gold.
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != player.id,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, over, _) => Draggable<int>(
        data: player.id,
        feedback: Material(
          type: MaterialType.transparency,
          child: Transform.scale(scale: 1.2, child: shirt(lit: true)),
        ),
        childWhenDragging: shirt(ghost: true),
        onDragStarted: HapticFeedback.selectionClick,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: picked || over.isNotEmpty ? 1.15 : 1,
            duration: const Duration(milliseconds: 160),
            child: shirt(lit: over.isNotEmpty),
          ),
        ),
      ),
    );
  }
}
