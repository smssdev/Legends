import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sounds.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/legend_crest.dart';
import '../../ui/widgets/motion.dart';
import '../../l10n/app_localizations.dart';

/// [2026-11-06] Whether the opening has played (once a launch): the router holds the start page until it has.
final introDoneProvider = NotifierProvider<IntroDone, bool>(IntroDone.new);

class IntroDone extends Notifier<bool> {
  @override
  bool build() => false;

  void finish() => state = true;
}

/// [2026-11-06, Sprint 47] The game's opening as in the approved design, about three seconds with its sound
/// (Sfx.intro): the night stadium, two floodlight towers whose beams sway, a pitch in perspective below; the crest
/// drops in and a mint ring spreads from it; the name GAME LEGEND MANAGER, «المدرب الأسطورة» in gold between two mint
/// dashes and the motto rise one after the other; a gold bar fills under a rolling ball. A tap skips it, and with less
/// motion asked (or in the widget tests) it goes straight on. While the account is still being checked after it, the
/// same scene stays, the ball rolling on.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  static const length = Duration(milliseconds: 3000);

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: IntroScreen.length);

  /// The motion that loops (the beams, the ring, the ball), on only when motion is.
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (still || !Ambient.on) {
        _c.value = 1;
        return _finish();
      }
      _loop.repeat();
      GameSounds.play(Sfx.intro);
      _c.forward().whenComplete(_finish);
    });
  }

  void _finish() {
    if (mounted) ref.read(introDoneProvider.notifier).finish();
  }

  @override
  void dispose() {
    _c.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// 0..1 over the part of the opening from [a] to [b] seconds.
  double _seg(double a, double b, [Curve curve = Curves.linear]) {
    final s = _c.value * IntroScreen.length.inMilliseconds / 1000;
    return curve.transform(((s - a) / (b - a)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final p = glmNight;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final waiting = ref.watch(introDoneProvider);
    return Scaffold(
      backgroundColor: p.bgDeep,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: waiting
            ? null
            : () {
                _c.stop();
                _finish();
              },
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _loop]),
          builder: (context, _) {
            final l = _loop.value;
            final crest = waiting ? 1.0 : _seg(.15, .95, Curves.easeOutBack);
            final r1 = waiting ? 1.0 : _seg(.55, 1.25, Curves.easeOutCubic);
            final r2 = waiting ? 1.0 : _seg(.75, 1.45, Curves.easeOutCubic);
            final r3 = waiting ? 1.0 : _seg(.95, 1.65, Curves.easeOutCubic);
            final bar = waiting ? (l * 1.3).clamp(0.04, 1.0) : _seg(.9, 3.0, Curves.easeInOut).clamp(0.04, 1.0);
            final sway = math.sin(l * math.pi * 2);
            return Stack(
              fit: StackFit.expand,
              children: [
                // The emerald halo behind the crest, breathing.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -.16),
                      radius: .85,
                      colors: [
                        p.brand.withValues(alpha: .22 + .1 * (.5 + .5 * sway)),
                        p.bgDeep.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                // The two beams from the towers, swaying in turn.
                CustomPaint(
                  painter: _Beams(sway: sway, light: const Color(0xFFFFF0C8)),
                ),
                // The towers.
                const Positioned(top: 16, left: 14, child: _Tower()),
                const Positioned(top: 16, right: 14, child: _Tower()),
                // The pitch in perspective at the bottom.
                Positioned(left: 0, right: 0, bottom: 0, height: 300, child: CustomPaint(painter: _Pitch(p))),
                // [Sprint 47] The phone is held sideways (the app is landscape): the crest at the reading start, the name,
                // the gold line, the motto and the bar beside it; upright, all in one column.
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final crestBox = SizedBox(
                        width: 170,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The mint ring spreading from the crest, again and again.
                            if (crest >= 1)
                              Opacity(
                                opacity: (1 - l).clamp(0.0, 1.0) * .9,
                                child: Container(
                                  width: 150 * (.7 + 1.2 * l),
                                  height: 150 * (.7 + 1.2 * l),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: p.ring, width: 2),
                                  ),
                                ),
                              ),
                            Opacity(
                              opacity: crest.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, (1 - crest) * 24),
                                child: Transform.scale(scale: .55 + .45 * crest, child: const LegendCrest(size: 150)),
                              ),
                            ),
                          ],
                        ),
                      );
                      final name = _Rise(
                        t: r1,
                        child: Text(
                          'GAME LEGEND MANAGER',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: GlmFonts.numbers,
                            fontWeight: FontWeight.w700,
                            fontSize: 36,
                            height: 1,
                            letterSpacing: 2,
                            color: p.text,
                          ),
                        ),
                      );
                      final gold = _Rise(
                        t: r1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 34, height: 2, color: p.ring),
                            const SizedBox(width: 10),
                            Text(
                              ar ? 'المدرب الأسطورة' : 'THE LEGEND COACH',
                              style: TextStyle(
                                fontFamily: ar ? GlmFonts.body : GlmFonts.numbers,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                letterSpacing: ar ? 0 : 2,
                                color: p.gold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 34, height: 2, color: p.ring),
                          ],
                        ),
                      );
                      final motto = _Rise(
                        t: r2,
                        child: Text(L.of(context).introTagline, style: TextStyle(fontSize: 15, color: p.textSoft)),
                      );
                      final barRow = _Rise(
                        t: r3,
                        child: SizedBox(
                          width: 190,
                          height: 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 9,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(color: p.text.withValues(alpha: .1), borderRadius: BorderRadius.circular(6)),
                                  alignment: AlignmentDirectional.centerStart,
                                  child: FractionallySizedBox(
                                    widthFactor: bar,
                                    child: Container(
                                      decoration: BoxDecoration(color: p.gold, borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                              ),
                              // The ball rolling at the bar's head.
                              PositionedDirectional(
                                start: bar * 190 - 12,
                                top: 0,
                                child: Transform.rotate(
                                  angle: bar * math.pi * 8 * (ar ? -1 : 1),
                                  child: CustomPaint(size: const Size.square(24), painter: BallPainter()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      final loading = _Rise(
                        t: r3,
                        child: Text(L.of(context).introLoading, style: TextStyle(fontSize: 14, color: p.textMuted)),
                      );
                      if (box.maxWidth > box.maxHeight) {
                        return Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 780,
                              height: 330,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Transform.scale(scale: 1.15, child: crestBox),
                                  const SizedBox(width: 40),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          name,
                                          const SizedBox(height: 12),
                                          gold,
                                          const SizedBox(height: 16),
                                          motto,
                                          const SizedBox(height: 34),
                                          barRow,
                                          const SizedBox(height: 10),
                                          loading,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 390,
                            height: 760,
                            child: Column(
                              children: [
                                const Spacer(flex: 5),
                                crestBox,
                                const SizedBox(height: 22),
                                name,
                                const SizedBox(height: 10),
                                gold,
                                const SizedBox(height: 22),
                                motto,
                                const Spacer(flex: 4),
                                barRow,
                                const SizedBox(height: 12),
                                loading,
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Rises into place as [t] goes from 0 to 1.
class _Rise extends StatelessWidget {
  const _Rise({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: t.clamp(0.0, 1.0),
    child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
  );
}

/// A floodlight tower: a bank of six lamps on a mast.
class _Tower extends StatelessWidget {
  const _Tower();

  @override
  Widget build(BuildContext context) => SizedBox(width: 66, height: 74, child: CustomPaint(painter: _TowerPainter(glmNight)));
}

class _TowerPainter extends CustomPainter {
  _TowerPainter(this.p);

  final GlmPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.scale(s.width / 64, s.height / 70);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 56, 34), const Radius.circular(6)), Paint()..color = p.surface);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 56, 34), const Radius.circular(6)),
      Paint()
        ..color = p.surfaceRaised
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final lamp = Paint()..color = const Color(0xFFFFF3D4);
    for (final y in [15.0, 28.0]) {
      for (final x in [16.0, 32.0, 48.0]) {
        canvas.drawCircle(Offset(x, y), 4, lamp);
      }
    }
    canvas.drawRect(const Rect.fromLTWH(29, 38, 6, 32), Paint()..color = p.surfaceRaised);
  }

  @override
  bool shouldRepaint(_TowerPainter old) => false;
}

/// The two beams from the towers' lamps, swaying in turn.
class _Beams extends CustomPainter {
  _Beams({required this.sway, required this.light});

  final double sway;
  final Color light;

  @override
  void paint(Canvas canvas, Size s) {
    for (final left in [true, false]) {
      final origin = Offset(left ? 47 : s.width - 47, 58);
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate((left ? 1 : -1) * (-.02 + .12 * (left ? sway : -sway)) + (left ? -.12 : .12));
      final h = s.height * .7, w = 230.0;
      final beam = Path()
        ..moveTo(-w * .05, 0)
        ..lineTo(w * .05, 0)
        ..lineTo(w / 2, h)
        ..lineTo(-w / 2, h)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [light.withValues(alpha: .32), light.withValues(alpha: 0)],
            stops: const [0, .8],
          ).createShader(Rect.fromLTWH(-w / 2, 0, w, h))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Beams old) => old.sway != sway;
}

/// The pitch in perspective, fading into the night at its top and bottom.
class _Pitch extends CustomPainter {
  _Pitch(this.p);

  final GlmPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height, k = w / 390;
    Offset o(double x, double y) => Offset(x * k, y * h / 300);
    final field = Path()..addPolygon([o(95, 0), o(295, 0), o(390, 300), o(0, 300)], true);
    canvas.drawPath(field, Paint()..color = p.pitchDark);
    final stripe = Paint()..color = p.pitch;
    for (final (a, b, c, d) in [(115.0, 155.0, 140.0, 60.0), (195.0, 235.0, 250.0, 170.0), (275.0, 295.0, 390.0, 330.0)]) {
      canvas.drawPath(Path()..addPolygon([o(a, 0), o(b, 0), o(c, 300), o(d, 300)], true), stripe);
    }
    final line = Paint()
      ..color = p.text.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(field, line);
    canvas.drawLine(o(72, 72), o(318, 72), line);
    canvas.drawOval(Rect.fromCenter(center: o(195, 72), width: 124 * k, height: 32 * h / 300), line);
    canvas.drawPath(Path()..addPolygon([o(120, 300), o(150, 190), o(240, 190), o(270, 300)], false), line);
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgDeep.withValues(alpha: .95), p.bgDeep.withValues(alpha: .15), p.bgDeep.withValues(alpha: .9)],
          stops: const [0, .45, 1],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(_Pitch old) => false;
}
