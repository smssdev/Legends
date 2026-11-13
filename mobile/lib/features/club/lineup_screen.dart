import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/pitch_name.dart';
import '../../ui/widgets/action_bar.dart';
import '../../ui/widgets/console.dart';
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

  /// [Sprint 60 F4] The lineup saves itself a moment after each change (as the site's), the approved draft's way.
  Timer? _autosave;

  void _changed() {
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 600), () => _save(quiet: true));
  }

  @override
  void dispose() {
    _autosave?.cancel();
    super.dispose();
  }

  LineupEditor get _editor => ref.read(lineupEditorProvider(widget.leagueId).notifier);
  TeamData? get _team => ref.read(teamProvider(widget.leagueId)).value;
  String? get _formation => _draft?.formation;
  List<int>? get _starters => _draft?.starters;
  List<int>? get _bench => _draft?.bench;
  bool get _busy => _draft?.busy ?? false;

  /// [2026-11-09] The places on the pitch: the saved formation at the places the coach dragged it to (on the site), or
  /// another formation at its own.
  List<Slot> _slots(TeamData t, List<Formation> formations) => _formation == t.lineup.formation
      ? t.lineup.slots
      : formations.where((f) => f.name == _formation).firstOrNull?.slots ?? t.lineup.slots;

  void _pickFormation(String? f) {
    final t = _team;
    if (f != null && t != null) {
      _editor.formation(f, t.lineup);
      _changed();
    }
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
    if (!done) return showGlmToast(context, L.of(context).keeperSlotOnly, error: true);
    _changed();
  }

  Future<void> _save({bool auto = false, bool quiet = false}) async {
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
      if (!quiet) showGlmToast(context, L.of(context).saved);
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
    // [Sprint 60 F4] Saving is automatic: the main action is the game's own lineup.
    final auto = GlmButton(
      label: l.autoLineup,
      block: true,
      loading: _busy,
      icon: const Icon(Icons.auto_awesome_rounded),
      onPressed: _busy ? null : () => _save(auto: true),
    );
    return Scaffold(
      appBar: GameBar(title: Text(l.lineup)),
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
                                style: glmText(GlmType.title, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800),
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
                      child: Text(l.dragHint, style: glmText(GlmType.caption, color: context.palette.textMuted)),
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
                horizontal: false,
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
                      child: Padding(padding: const EdgeInsets.all(12), child: auto),
                    ),
                  ],
                );
              }
              // [Sprint 60 F4] The approved draft's lineup (Lineup.html): the pitch at the screen's height in the middle, the
              // same flat pitch as the tactics', the formations in a column at one side, the bench and the rest in a column
              // at the other, and every action in the bar at the foot, the game's own lineup the main one.
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: GlmCard(
                        padding: const EdgeInsets.all(GlmSpace.sm),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            GlmSectionTitle(l.formation),
                            const SizedBox(height: GlmSpace.xs),
                            Wrap(
                              spacing: GlmSpace.xs,
                              runSpacing: GlmSpace.xs,
                              children: [
                                for (final f in formations)
                                  ChoiceChip(
                                    label: Text(f.label, textDirection: TextDirection.ltr),
                                    selected: f.name == _formation,
                                    onSelected: (_) => _pickFormation(f.name),
                                  ),
                              ],
                            ),
                            hint,
                            const SizedBox(height: GlmSpace.sm),
                            // The lineup's other pages, by their names (no circle without a name).
                            Wrap(
                              children: [
                                GlmActionItem(
                                  icon: const GameIcon(GameGlyph.tactics, size: 24),
                                  label: l.tactics,
                                  onTap: () => context.push('/leagues/${widget.leagueId}/tactics'),
                                ),
                                GlmActionItem(
                                  icon: const GameIcon(GameGlyph.specialists, size: 24),
                                  label: l.specialists,
                                  onTap: () => context.push('/leagues/${widget.leagueId}/specialists'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AspectRatio(aspectRatio: 68 / 105, child: pitch),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlmCard(
                        padding: const EdgeInsets.all(GlmSpace.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ListView(padding: EdgeInsets.zero, children: lists),
                            ),
                            const SizedBox(height: GlmSpace.sm),
                            // The approved draft's main action at the screen's foot, at its end: the game's own lineup.
                            auto,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
        const tokenW = 56.0, tokenH = 48.0;
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
      // [Sprint 60 F4] The approved draft's place on the pitch: a disc with his rating (gold when picked), his name under it.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: picked || lit ? context.palette.gold : c.bg,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(
              '${player.overall}',
              style: context.type
                  .numbers(context.type.caption)
                  .copyWith(color: picked || lit ? context.palette.onGold : c.fg, fontWeight: FontWeight.w800, height: 1),
            ),
          ),
          const SizedBox(height: 1),
          PitchName(player.name.split(' ').last, width: 56),
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
