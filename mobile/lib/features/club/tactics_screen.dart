import '../../ui/art_palette.dart';

import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/widgets/console.dart';
import '../../ui/widgets/glm_card.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../core/sounds.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/game_icons.dart';
import '../../ui/widgets/stadium.dart';
import '../leagues/models.dart';
import 'club_data.dart';
import 'tactics_controller.dart';
import 'flat_pitch.dart';
import 'team_data.dart';
import '../leagues/shell.dart';

part 'tactics_screen_round_dial.dart';
part 'tactics_screen_dial.dart';

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
  // [Sprint 59 F5] The edit lives in TacticsEditor; the screen draws it and says what failed.
  TacticsEditor get _editor => ref.read(tacticsEditorProvider(widget.leagueId).notifier);

  void _failed(ApiError? e) {
    if (e != null && mounted) showGlmToast(context, e.message, error: true);
  }

  /// [Sprint 50 M12] A ready philosophy: the server sets its keys, and the screen takes what it answers.
  Future<void> _preset(String preset) async => _failed(await _editor.preset(preset));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: GameBar(title: Text(l.tactics)),
      body: GlmBackground(
        wide: true,
        child: AsyncView(
          value: ref.watch(tacticsProvider(widget.leagueId)),
          onRetry: () => ref.invalidate(tacticsProvider(widget.leagueId)),
          data: (loaded) {
            final t = ref.watch(tacticsEditorProvider(widget.leagueId)) ?? loaded;
            _editor.onError = _failed;
            void set(String key, Object v) => _editor.set(key, v, t);
            final l = L.of(context);
            final summary = ref.watch(clubSummaryProvider(widget.leagueId)).value;
            Widget gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w);
            Widget pair(Widget a, Widget b) => LayoutBuilder(
              builder: (context, box) => box.maxWidth < 560
                  ? Column(children: [gap(a), gap(b)])
                  : gap(
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: a),
                            const SizedBox(width: 12),
                            Expanded(child: b),
                          ],
                        ),
                      ),
                    ),
            );
            String level(num v) => v < 40
                ? l.low
                : v > 60
                ? l.high
                : l.balancedWord;
            // [Sprint 46, the owner's screenshots] The tactics as the manager games set them: the next match first, then
            // each choice a card of its own, turned with its arrows and drawn (the plan on a little pitch, the lines on a
            // tall one), the three dials as sliders with their number, the trap and the marking.
            // [Sprint 50 M12] The console: the live preview on one half (the plan drawn, the trap's line, the ready
            // philosophies) in front of the dials on the other, so a turn of a dial shows at once beside it.
            return LayoutBuilder(
              builder: (context, box) {
                // [Sprint 60 F4] The approved draft's tactics (Tactics.html): the lineup's own pitch in the same place, so going
                // from one to the other does not move the eye; the choices as buttons at its start, the dials one column at its
                // end. Saved by itself, as before.
                if (box.maxWidth >= 560) {
                  final team = ref.watch(teamProvider(widget.leagueId)).value;
                  String presetName(String x) => switch (x) {
                    'tiki_taka' => l.presetTikiTaka,
                    'counter' => l.presetCounter,
                    'high_press' => l.presetHighPress,
                    _ => l.presetLongBall,
                  };
                  Widget choices<T>(String title, List<(T, String)> options, T now, void Function(T) pick) => Padding(
                    padding: const EdgeInsets.only(bottom: GlmSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlmSectionTitle(title),
                        const SizedBox(height: GlmSpace.xs),
                        Wrap(
                          spacing: GlmSpace.xs,
                          runSpacing: GlmSpace.xs,
                          children: [
                            for (final (v, label) in options)
                              ChoiceChip(label: Text(label), selected: v == now, onSelected: (_) => pick(v)),
                          ],
                        ),
                      ],
                    ),
                  );
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
                                choices<String>(
                                  l.plan,
                                  [
                                    ('passing', l.planPassing),
                                    ('counter', l.planCounter),
                                    ('long', l.planLong),
                                    ('wings', l.planWings),
                                    ('shots', l.planShots),
                                  ],
                                  '${t.values['plan']}',
                                  (v) => set('plan', v),
                                ),
                                choices<String>(
                                  l.marking,
                                  [('zone', l.markZone), ('man', l.markMan)],
                                  '${t.values['marking']}',
                                  (v) => set('marking', v),
                                ),
                                choices<int>(
                                  l.tackling,
                                  [
                                    for (final v in const [0, 1, 2, 3]) (v, {0: l.tackle0, 1: l.tackle1, 2: l.tackle2, 3: l.tackle3}[v]!),
                                  ],
                                  (t.values['tackling'] as num).toInt(),
                                  (v) => set('tackling', v),
                                ),
                                choices<int>(l.trap, [(0, l.no), (1, l.yes)], (t.values['trap'] as num).toInt(), (v) => set('trap', v)),
                                if (t.presets.isNotEmpty)
                                  choices<String>(l.presets, [for (final x in t.presets) (x, presetName(x))], t.preset ?? '', _preset),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AspectRatio(
                          aspectRatio: 68 / 105,
                          child: team == null ? const FlatPitch(child: SizedBox.shrink()) : ElevenOnPitch(team: team),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GlmCard(
                            padding: const EdgeInsets.all(GlmSpace.sm),
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                for (final (key, title, lo, hi) in [
                                  ('style', l.mentality, l.defensive, l.attacking),
                                  ('pressing', l.pressing, l.calm, l.suffocating),
                                  ('tempo', l.tempo, l.slow, l.fast),
                                ])
                                  _SliderRow(
                                    title: title,
                                    value: t.get<num>(key).toDouble(),
                                    word: level(t.get<num>(key)),
                                    low: lo,
                                    high: hi,
                                    onChanged: (v) => set(key, v.round()),
                                  ),
                                const SizedBox(height: GlmSpace.sm),
                                _Lines(t: t, onSet: set),
                                const SizedBox(height: GlmSpace.sm),
                                Row(
                                  children: [
                                    Icon(Icons.lock_rounded, size: 15, color: context.palette.brandLight),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(l.hiddenTactics, style: context.type.caption)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    if (summary != null) gap(_NextCard(s: summary)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l.prepareTactics,
                        textAlign: TextAlign.center,
                        style: glmText(
                          GlmType.headline,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          shadows: [const Shadow(color: Colors.black54, blurRadius: 6)],
                        ),
                      ),
                    ),
                    pair(
                      _Carousel(
                        title: l.plan,
                        values: const ['shots', 'counter', 'long', 'passing', 'wings'],
                        value: '${t.values['plan']}',
                        label: (v) => {
                          'passing': l.planPassing,
                          'counter': l.planCounter,
                          'long': l.planLong,
                          'wings': l.planWings,
                          'shots': l.planShots,
                        }[v]!,
                        picture: (v) => SizedBox(
                          height: 120,
                          // [Sprint 46, the polish] The plan's arrows trace themselves in as it is chosen.
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(v),
                            tween: Tween(begin: MediaQuery.of(context).disableAnimations ? 1 : 0, end: 1),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeInOutCubic,
                            builder: (_, t, _) => CustomPaint(painter: _PlanArt(v, t), size: Size.infinite),
                          ),
                        ),
                        onChanged: (v) => set('plan', v),
                      ),
                      _Carousel(
                        title: l.tackling,
                        values: const [3, 2, 1, 0],
                        value: (t.values['tackling'] as num).toInt(),
                        label: (v) => {0: l.tackle0, 1: l.tackle1, 2: l.tackle2, 3: l.tackle3}[v]!,
                        picture: (v) => SizedBox(
                          height: 120,
                          child: CustomPaint(painter: _TackleArt(v), size: Size.infinite),
                        ),
                        onChanged: (v) => set('tackling', v),
                      ),
                    ),
                    gap(_Lines(t: t, onSet: set)),
                    for (final (key, title, lo, hi) in [
                      ('pressing', l.pressing, l.low, l.high),
                      ('style', l.style, l.defensive, l.attacking),
                      ('tempo', l.tempo, l.calm, l.fast),
                    ])
                      gap(
                        _Dial(
                          title: title,
                          value: t.get<num>(key),
                          word: level(t.get<num>(key)),
                          low: lo,
                          high: hi,
                          onChanged: (v) => set(key, v),
                        ),
                      ),
                    pair(
                      _Carousel(
                        title: l.marking,
                        values: const ['zone', 'man'],
                        value: '${t.values['marking']}',
                        label: (v) => v == 'zone' ? l.markZone : l.markMan,
                        picture: (v) => SizedBox(
                          height: 110,
                          child: CustomPaint(painter: _MarkArt(v), size: Size.infinite),
                        ),
                        onChanged: (v) => set('marking', v),
                      ),
                      _Carousel(
                        title: l.trap,
                        values: const [0, 1],
                        value: (t.values['trap'] as num).toInt(),
                        label: (v) => v == 1 ? l.yes : l.no,
                        picture: (v) => SizedBox(
                          height: 110,
                          child: CustomPaint(painter: _TrapArt(v == 1), size: Size.infinite),
                        ),
                        onChanged: (v) => set('trap', v),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// [Sprint 60 F4] One dial of the tactics as the draft's slider: its name and where it stands, the slider, and its two
/// ends' names under it.
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.title,
    required this.value,
    required this.word,
    required this.low,
    required this.high,
    required this.onChanged,
  });

  final String title, word, low, high;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: GlmSpace.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: context.type.body.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(word, style: context.type.caption.copyWith(color: context.glm.goldText)),
          ],
        ),
        Slider(value: value.clamp(0, 100), max: 100, onChanged: onChanged, semanticFormatterCallback: (v) => '$title ${v.round()}'),
        Row(
          children: [
            Expanded(child: Text(low, style: context.type.caption)),
            Text(high, style: context.type.caption),
          ],
        ),
      ],
    ),
  );
}
