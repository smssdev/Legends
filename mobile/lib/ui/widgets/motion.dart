import 'dart:async';

import 'package:flutter/material.dart';

/// [2026-11-06] The app's motion, small and purposeful: things arrive (a fade and a short rise, staggered down a
/// list), live things pulse, numbers count up to their value, and what can be pressed sinks a little under the finger.
/// All of it stands still when the phone asks for less motion.
bool _still(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// The motion that never ends (a sheen passing, a pulse): on in the app, off in the widget tests
/// (test/flutter_test_config.dart), which wait for the screen to settle.
abstract final class Ambient {
  static bool on = true;
}

/// Fades and rises into place, [index] steps after the first (40 ms each, at most 8 steps).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 18});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  // [Sprint 59 F7] A Timer, cancelled with the widget (a Future.delayed outlived it).
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    _wait = Timer(Duration(milliseconds: 40 * widget.index.clamp(0, 8)), _c.forward);
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, (1 - _t.value) * widget.offset), child: child),
      ),
      child: widget.child,
    );
  }
}

/// A soft repeating pulse (a live badge, something waiting for the coach).
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.min = .55});

  final Widget child;
  final double min;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_still(context) || !Ambient.on) {
      _c.stop();
      return widget.child;
    }
    // [Sprint 61 F5] The pulse repaints only itself.
    return RepaintBoundary(
      child: FadeTransition(
        opacity: Tween(begin: widget.min, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      ),
    );
  }
}

/// A number that counts up to its value when it first shows (a balance, a record, the points).
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style, this.format});

  final int value;
  final TextStyle? style;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    final f = format ?? (int v) => '$v';
    if (_still(context)) return Text(f(value), style: style, textDirection: TextDirection.ltr);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(f(v.round()), style: style, textDirection: TextDirection.ltr),
    );
  }
}

/// Sinks a little while pressed: the feel of a game button.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scaled = AnimatedScale(
      scale: _down ? .97 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: widget.child,
    );
    // Without its own tap (a card whose InkWell takes it), it only listens to the finger, never stealing the tap.
    if (widget.onTap == null) {
      return Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: scaled,
      );
    }
    return _tapper();
  }

  Widget _tapper() => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
    onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
    onTapCancel: () => setState(() => _down = false),
    onTap: widget.onTap,
    child: AnimatedScale(scale: _down ? .96 : 1, duration: const Duration(milliseconds: 110), curve: Curves.easeOut, child: widget.child),
  );
}

/// [Sprint 47] A football that rolls a little to and fro, turning as it goes (the simulator's door, a waiting screen).
class RollingBall extends StatefulWidget {
  const RollingBall({super.key, this.size = 24, this.travel = 10});

  final double size, travel;

  @override
  State<RollingBall> createState() => _RollingBallState();
}

class _RollingBallState extends State<RollingBall> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_still(context) && Ambient.on) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ball = CustomPaint(size: Size.square(widget.size), painter: BallPainter());
    if (!_c.isAnimating) return ball;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_c.value) * 2 - 1;
          final dx = t * widget.travel;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.rotate(angle: dx / (widget.size / 2), child: child),
          );
        },
        child: ball,
      ),
    );
  }
}

/// A white ball with its dark patch, in the game's night colours.
class BallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    const white = Color(0xFFF7F4EA), ink = Color(0xFF06111E);
    final c = s.center(Offset.zero), r = s.width / 2 - 1;
    canvas.drawCircle(c, r, Paint()..color = white);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width / 16,
    );
    final k = s.width / 24;
    canvas.drawPath(
      Path()..addPolygon([
        Offset(12 * k, 7 * k),
        Offset(16 * k, 10 * k),
        Offset(14.5 * k, 15 * k),
        Offset(9.5 * k, 15 * k),
        Offset(8 * k, 10 * k),
      ], true),
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(BallPainter old) => false;
}
