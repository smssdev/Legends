import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/kit.dart';
import '../../ui/widgets/motion.dart';
import 'squad_screen.dart';
import 'team_data.dart';

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
      appBar: AppBar(title: Text(l.lineup), actions: [
        TextButton.icon(
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
            final wide = box.maxWidth >= 640;
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
                Expanded(child: Text(l.tapToSwap, style: TextStyle(color: context.palette.textMuted, fontSize: 12))),
              ]),
            );
            final pitch = _Pitch(slots: slots, starters: _starters!, team: t, picked: _picked, onTap: _tap, horizontal: wide);
            final lists = [
              GameHeader(l.bench, icon: Icons.event_seat_rounded),
              for (final (i, id) in _bench!.indexed)
                if (t.byId(id) case final p?) FadeSlideIn(index: i, child: PlayerRow(p, selected: _picked == id, onTap: () => _tap(id))),
              if (others.isNotEmpty) ...[
                GameHeader(l.reserve, icon: Icons.groups_rounded),
                for (final p in others) PlayerRow(p, selected: _picked == p.id, onTap: () => _tap(p.id)),
              ],
            ];
            if (!wide) {
              return Column(children: [
                Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [formation, hint, const SizedBox(height: 10), pitch, ...lists])),
                SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: save)),
              ]);
            }
            // [2026-11-06, stage 3] Landscape: the pitch lying across the screen on one side, the formation, the bench
            // and the reserves on the other, and «save» always in reach at the bottom of that side.
            return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                  child: Center(child: AspectRatio(aspectRatio: 1.5, child: pitch)),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(children: [
                  Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(8, 8, 16, 8), children: [formation, hint, ...lists])),
                  Padding(padding: const EdgeInsets.fromLTRB(8, 0, 16, 12), child: save),
                ]),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({required this.slots, required this.starters, required this.team, required this.picked, required this.onTap, this.horizontal = false});

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
                  child: _Token(player: pl, line: slots[i].line, picked: picked == pl.id, onTap: () => onTap(pl.id)),
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
  const _Token({required this.player, required this.line, required this.picked, required this.onTap});

  final Player player;
  final String line;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = lineColor(line);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: picked ? 1.12 : 1,
        duration: const Duration(milliseconds: 160),
        child: Column(children: [
          KitShirt(color: picked ? context.palette.gold : c.bg, trim: Colors.white, label: '${player.overall}', size: 44, picked: picked),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(5)),
            child: Text(player.name.split(' ').last, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
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
