import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_card.dart';
import 'team_data.dart';

/// [Sprint 17 F1] The tactics (the web's TacticsPage): the plan, the tackling, the three sliders, the three lines, the
/// trap and the marking. Saved by itself a moment after each change (Sprint 27), and refused from the lock five minutes
/// before a match (the server's message). Only the plan, tackling, trap and marking ever reach the opponent.
class TacticsScreen extends ConsumerStatefulWidget {
  const TacticsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<TacticsScreen> createState() => _TacticsScreenState();
}

class _TacticsScreenState extends ConsumerState<TacticsScreen> {
  Tactics? _t;
  final Map<String, Object> _pending = {};
  Timer? _timer;
  late final TeamRepository _repo = ref.read(teamRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _repo; // taken now: a change still unsaved is sent on the way out, when ref can no longer be read
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_pending.isNotEmpty) unawaited(_repo.saveTactics(widget.leagueId, Map.of(_pending)).catchError((_) => const Tactics({})));
    super.dispose();
  }

  void _set(String key, Object v) {
    setState(() => _t = _t!.set(key, v));
    _pending[key] = v;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), _flush);
  }

  Future<void> _flush() async {
    if (_pending.isEmpty) return;
    final changes = Map.of(_pending);
    _pending.clear();
    try {
      await _repo.saveTactics(widget.leagueId, changes);
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
      ref.invalidate(tacticsProvider(widget.leagueId));
      if (mounted) setState(() => _t = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tactics)),
      body: GlmBackground(
        child: AsyncView(
          value: ref.watch(tacticsProvider(widget.leagueId)),
          onRetry: () => ref.invalidate(tacticsProvider(widget.leagueId)),
          data: (loaded) {
            final t = _t ??= loaded;
            Widget choice<T extends Object>(String title, String key, Map<T, String> options) => GlmCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(title, style: context.text.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final o in options.entries)
                        ChoiceChip(
                          label: Text(o.value),
                          selected: t.values[key] == o.key,
                          selectedColor: context.palette.gold.withValues(alpha: .28),
                          onSelected: (_) => _set(key, o.key),
                        ),
                    ]),
                  ]),
                );
            Widget slider(String title, String key, String low, String high) => GlmCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [Text(title, style: context.text.titleMedium), const Spacer(), Text('${t.get<num>(key).round()}', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 20, fontWeight: FontWeight.w800, color: context.glm.goldText))]),
                    Slider(value: t.get<num>(key).toDouble(), min: 0, max: 100, divisions: 20, activeColor: context.palette.gold, onChanged: (v) => _set(key, v.round())),
                    Row(children: [Text(low, style: TextStyle(color: context.palette.textMuted, fontSize: 12)), const Spacer(), Text(high, style: TextStyle(color: context.palette.textMuted, fontSize: 12))]),
                  ]),
                );
            const gap = SizedBox(height: 10);
            return ListView(padding: const EdgeInsets.all(12), children: [
              Text(l.savesItself, textAlign: TextAlign.center, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
              gap,
              choice(l.plan, 'plan', {'passing': l.planPassing, 'counter': l.planCounter, 'long': l.planLong, 'wings': l.planWings, 'shots': l.planShots}),
              gap,
              slider(l.pressing, 'pressing', l.low, l.high),
              gap,
              slider(l.style, 'style', l.defensive, l.attacking),
              gap,
              slider(l.tempo, 'tempo', l.calm, l.fast),
              gap,
              choice(l.tackling, 'tackling', {0: l.tackle0, 1: l.tackle1, 2: l.tackle2, 3: l.tackle3}),
              gap,
              choice(l.lineAtt, 'att', {'back': l.attBack, 'support': l.attSupport, 'only': l.attOnly}),
              gap,
              choice(l.lineMid, 'mid', {'def': l.midDef, 'stay': l.midStay, 'push': l.midPush}),
              gap,
              choice(l.lineDef, 'def', {'stay': l.defStay, 'fullbacks': l.defFullbacks, 'mid': l.defMid}),
              gap,
              choice(l.marking, 'marking', {'zone': l.markZone, 'man': l.markMan}),
              gap,
              GlmCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.trap, style: context.text.titleMedium), value: t.values['trap'] == 1,
                    activeThumbColor: context.palette.gold, onChanged: (v) => _set('trap', v ? 1 : 0)),
              ),
              const SizedBox(height: 24),
            ]);
          },
        ),
      ),
    );
  }
}
