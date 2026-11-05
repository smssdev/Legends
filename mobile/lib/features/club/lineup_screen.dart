import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l.lineup), actions: [
        TextButton(onPressed: _busy ? null : () => _save(auto: true), child: Text(l.autoLineup, style: TextStyle(color: context.glm.goldText))),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(padding: const EdgeInsets.all(12), child: GlmButton(label: l.save, block: true, loading: _busy, onPressed: _formation != null && _dirty ? _save : null)),
      ),
      body: GlmBackground(
        child: AsyncView(
          value: team,
          onRetry: () => ref.invalidate(teamProvider(widget.leagueId)),
          data: (t) {
            _load(t);
            final slots = formations.where((f) => f.name == _formation).firstOrNull?.slots ?? t.lineup.slots;
            final others = t.players.where((p) => !_starters!.contains(p.id) && !_bench!.contains(p.id)).toList();
            return ListView(padding: const EdgeInsets.all(12), children: [
              Row(children: [
                Text(l.formation, style: context.text.titleMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: formations.any((f) => f.name == _formation) ? _formation : null,
                    hint: Text(_formation ?? ''),
                    items: [for (final f in formations) DropdownMenuItem(value: f.name, child: Text(f.label, textDirection: TextDirection.ltr))],
                    onChanged: (v) => setState(() => _formation = v),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(l.tapToSwap, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
              const SizedBox(height: 10),
              _Pitch(slots: slots, starters: _starters!, team: t, picked: _picked, onTap: _tap),
              SectionTitle(l.bench),
              for (final id in _bench!)
                if (t.byId(id) case final p?) PlayerRow(p, selected: _picked == id, onTap: () => _tap(id)),
              if (others.isNotEmpty) ...[
                SectionTitle(l.reserve),
                for (final p in others) PlayerRow(p, selected: _picked == p.id, onTap: () => _tap(p.id)),
              ],
            ]);
          },
        ),
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({required this.slots, required this.starters, required this.team, required this.picked, required this.onTap});

  final List<Slot> slots;
  final List<int> starters;
  final TeamData team;
  final int? picked;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AspectRatio(
      aspectRatio: 0.78,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.pitch, p.pitchDark]),
          ),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _Lines(Colors.white.withValues(alpha: .35)))),
            for (var i = 0; i < slots.length && i < starters.length; i++)
              if (team.byId(starters[i]) case final pl?)
                Positioned(
                  // x runs from my goal (the bottom) forward (the top), y across.
                  left: (slots[i].y / 680) * (w - 76),
                  top: (1 - slots[i].x / 740).clamp(0.0, 1.0) * (h - 64),
                  width: 76,
                  child: GestureDetector(
                    onTap: () => onTap(pl.id),
                    child: Column(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: picked == pl.id ? p.gold : lineColor(slots[i].line).bg,
                        child: Text('${pl.overall}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16, color: picked == pl.id ? p.onGold : lineColor(slots[i].line).fg)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .45), borderRadius: BorderRadius.circular(4)),
                        child: Text(pl.name.split(' ').last, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),
          ]),
        );
      }),
    );
  }
}

class _Lines extends CustomPainter {
  _Lines(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final pen = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6, 6, s.width - 12, s.height - 12), const Radius.circular(12)), pen);
    canvas.drawLine(Offset(6, s.height / 2), Offset(s.width - 6, s.height / 2), pen);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * .14, pen);
    for (final top in [true, false]) {
      final y = top ? 6.0 : s.height - 6;
      final d = top ? 1 : -1;
      canvas.drawRect(Rect.fromPoints(Offset(s.width * .22, y), Offset(s.width * .78, y + d * s.height * .15)), pen);
      canvas.drawRect(Rect.fromPoints(Offset(s.width * .38, y), Offset(s.width * .62, y + d * s.height * .06)), pen);
    }
  }

  @override
  bool shouldRepaint(_Lines old) => old.color != color;
}
