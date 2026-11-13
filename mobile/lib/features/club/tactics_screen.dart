import '../../ui/art_palette.dart';

import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/widgets/console.dart';

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
                if (box.maxWidth >= 760) {
                  return GlmSplitLayout(
                    start: _Preview(t: t, onPreset: _preset),
                    end: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Row(
                          children: [
                            for (final (key, title, lo, hi) in [
                              ('style', l.mentality, l.defensive, l.attacking),
                              ('pressing', l.pressing, l.calm, l.suffocating),
                              ('tempo', l.tempo, l.slow, l.fast),
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: _RoundDial(
                                    title: title,
                                    value: t.get<num>(key).toInt(),
                                    low: lo,
                                    high: hi,
                                    onChanged: (v) => set(key, v),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        gap(_Lines(t: t, onSet: set)),
                        pair(
                          _Carousel(
                            title: l.marking,
                            values: const ['zone', 'man'],
                            value: '${t.values['marking']}',
                            label: (v) => v == 'zone' ? l.markZone : l.markMan,
                            picture: (v) => SizedBox(
                              height: 90,
                              child: CustomPaint(painter: _MarkArt(v), size: Size.infinite),
                            ),
                            onChanged: (v) => set('marking', v),
                          ),
                          _Carousel(
                            title: l.tackling,
                            values: const [3, 2, 1, 0],
                            value: (t.values['tackling'] as num).toInt(),
                            label: (v) => {0: l.tackle0, 1: l.tackle1, 2: l.tackle2, 3: l.tackle3}[v]!,
                            picture: (v) => SizedBox(
                              height: 90,
                              child: CustomPaint(painter: _TackleArt(v), size: Size.infinite),
                            ),
                            onChanged: (v) => set('tackling', v),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_rounded, size: 15, color: context.palette.brandLight),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(l.hiddenTactics, style: glmText(GlmType.caption, color: context.palette.textMuted)),
                            ),
                          ],
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

/// [Sprint 50 M12] The preview half: the plan drawn large on its pitch (traced in again at each change), the offside
/// trap's high line when it is set, and the ready philosophies under it (the one the tactics match lit in gold).
class _Preview extends StatelessWidget {
  const _Preview({required this.t, required this.onPreset});

  final Tactics t;
  final ValueChanged<String> onPreset;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final plan = '${t.values['plan']}';
    final trap = (t.values['trap'] as num?)?.toInt() == 1;
    String name(String x) => switch (x) {
      'tiki_taka' => l.presetTikiTaka,
      'counter' => l.presetCounter,
      'high_press' => l.presetHighPress,
      _ => l.presetLongBall,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: ShapeDecoration(
              shape: GlmCut.shape(14, side: BorderSide(color: p.text.withValues(alpha: .25))),
              gradient: _cardFill,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('$plan:${t.values['style']}:${t.values['tempo']}'),
                    tween: Tween(begin: MediaQuery.of(context).disableAnimations ? 1 : 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOutCubic,
                    builder: (_, v, _) => CustomPaint(painter: _PlanArt(plan, v)),
                  ),
                ),
                if (trap)
                  PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    end: 0,
                    start: 0,
                    child: Align(
                      alignment: const AlignmentDirectional(-.18, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: p.bgDeep.withValues(alpha: .8), borderRadius: BorderRadius.circular(4)),
                            child: Text(l.trap, style: glmText(GlmType.caption, color: p.goldLight)),
                          ),
                          Expanded(child: Container(width: 2, color: p.goldLight.withValues(alpha: .8))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final x in t.presets)
              ChoiceChip(
                label: Text(name(x)),
                selected: t.preset == x,
                onSelected: (_) => onPreset(x),
                showCheckmark: false,
                selectedColor: p.gold,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, color: t.preset == x ? p.onGold : p.text),
                side: BorderSide(color: t.preset == x ? p.gold : p.surfaceRaised),
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ],
        ),
      ],
    );
  }
}
