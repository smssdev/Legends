import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sounds.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart' show GlmLoader;
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/motion.dart';
import '../../ui/widgets/stadium.dart';

/// [2026-11-06] Whether the opening has played (once a launch): the router holds the start page until it has.
final introDoneProvider = NotifierProvider<IntroDone, bool>(IntroDone.new);

class IntroDone extends Notifier<bool> {
  @override
  bool build() => false;

  void finish() => state = true;
}

/// [2026-11-06] The game's opening, about three seconds, its sound with it (Sfx.intro): the stadium is dark; the
/// floodlights come on, one bank then the other, each with a flicker; the crest drops into the light and lands with a
/// gold ring; a sheen crosses it; the name slides in on a gold slab in the Legend Cut; gold sparks rise; then the game.
/// A tap skips it, and with less motion asked (or in the widget tests) it goes straight on.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  static const length = Duration(milliseconds: 3000);

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: IntroScreen.length);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (still || !Ambient.on) return _finish();
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
    super.dispose();
  }

  /// 0..1 over the part of the opening from [a] to [b] seconds.
  double _seg(double a, double b, [Curve curve = Curves.linear]) {
    final s = _c.value * IntroScreen.length.inMilliseconds / 1000;
    return curve.transform(((s - a) / (b - a)).clamp(0.0, 1.0));
  }

  /// A lamp coming on: off, a flicker, on.
  double _lamp(double at) {
    final s = _c.value * IntroScreen.length.inMilliseconds / 1000 - at;
    if (s < 0) return 0;
    if (s < .05) return .9;
    if (s < .09) return .2;
    if (s < .14) return 1;
    if (s < .17) return .5;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    // Played, but the account is still being checked (a slow network): the crest on the stadium, and the ball waiting.
    if (ref.watch(introDoneProvider)) {
      return Scaffold(
        backgroundColor: p.bgDeep,
        body: StadiumBackdrop(
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [BrandMark(size: 110, stacked: true), SizedBox(height: 20), GlmLoader()])),
        ),
      );
    }
    return Scaffold(
      backgroundColor: p.bgDeep,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _c.stop();
          _finish();
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final left = _lamp(.12), right = _lamp(.48);
            final drop = _seg(.95, 1.45, Curves.easeOutBack);
            final ring = _seg(1.35, 2.1, Curves.easeOutCubic);
            final shine = _seg(1.5, 2.1, Curves.easeInOut);
            final slab = _seg(1.55, 2.0, Curves.easeOutCubic);
            final sub = _seg(1.85, 2.25);
            final out = _seg(2.65, 3.0);
            return Opacity(
              opacity: 1 - out,
              child: Stack(fit: StackFit.expand, children: [
                const StadiumBackdrop(),
                // The dark, lifting with each bank of lights: the left half with the first, the right with the second.
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: ColoredBox(color: p.bgDeep.withValues(alpha: (1 - left * .92).clamp(0, 1)), child: const SizedBox.expand())),
                  Expanded(child: ColoredBox(color: p.bgDeep.withValues(alpha: (1 - right * .92).clamp(0, 1)), child: const SizedBox.expand())),
                ]),
                // The sparks rising once the crest has landed.
                if (ring > 0) CustomPaint(painter: _Sparks(t: _seg(1.35, 3.0), color: p.goldLight)),
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 220,
                      height: 170,
                      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                        // The gold ring as it lands.
                        if (ring > 0 && ring < 1)
                          Container(
                            width: 120 + ring * 200,
                            height: 120 + ring * 200,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.gold.withValues(alpha: (1 - ring) * .8), width: 3 * (1 - ring) + 1)),
                          ),
                        // Its glow.
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [p.gold.withValues(alpha: .28 * drop.clamp(0, 1)), p.gold.withValues(alpha: 0)])),
                        ),
                        Opacity(
                          opacity: drop.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, (1 - drop) * -60),
                            child: Transform.scale(
                              scale: 1.5 - .5 * drop,
                              child: _Sheen(t: shine, child: Image.asset(ar ? 'assets/brand/emblem-ar.png' : 'assets/brand/emblem.png', width: 150, height: 150)),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    // The name on a gold slab, sliding in from the reading start.
                    ClipRect(
                      child: Align(
                        widthFactor: 1,
                        child: Transform.translate(
                          offset: Offset((Directionality.of(context) == TextDirection.rtl ? 1 : -1) * (1 - slab) * 260, 0),
                          child: Opacity(
                            opacity: slab,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                              decoration: ShapeDecoration(
                                shape: GlmCut.shape(14),
                                gradient: LinearGradient(colors: [p.goldLight, p.gold, p.goldDark], stops: const [0, .5, 1]),
                                shadows: [BoxShadow(color: p.gold.withValues(alpha: .35), blurRadius: 24, spreadRadius: -6)],
                              ),
                              child: Text('GAME LEGEND MANAGER', textDirection: TextDirection.ltr,
                                  style: TextStyle(fontFamily: GlmFonts.body, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 3, color: p.onGold)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: sub,
                      child: Text(ar ? 'المدرب الأسطورة' : 'ONLINE FOOTBALL MANAGER',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: ar ? 0 : 3,
                              shadows: [Shadow(color: Colors.black.withValues(alpha: .6), blurRadius: 10)])),
                    ),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

/// A band of light crossing the crest once.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return child;
    final x = -1.6 + t * 3.2;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment(x - .4, -1),
        end: Alignment(x + .4, 1),
        colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .55), Colors.white.withValues(alpha: 0)],
      ).createShader(r),
      child: child,
    );
  }
}

/// Gold sparks drifting up from the pitch, each on its own path (the same every time).
class _Sparks extends CustomPainter {
  _Sparks({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(11);
    final paint = Paint();
    for (var i = 0; i < 46; i++) {
      final x0 = rnd.nextDouble() * s.width, delay = rnd.nextDouble() * .45, speed = .5 + rnd.nextDouble() * .7, r = .8 + rnd.nextDouble() * 2.2;
      final k = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final y = s.height * (1.02 - k * speed * .9);
      final x = x0 + math.sin(k * 6 + i) * 14;
      paint.color = color.withValues(alpha: (1 - k) * .85);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_Sparks old) => old.t != t;
}
