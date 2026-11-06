import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// [2026-11-06, the game's signature] «قَصّة الأسطورة», the Legend Cut: every card, button and badge has two corners
/// cut at 45° — the start of its top and the end of its bottom, like a sports broadcast's graphics or a captain's
/// armband — with a short gold line on the upper cut. The other two corners are barely rounded. It is the game's
/// mark: a screen of ours is known by it at a glance, in Arabic (the cut mirrors) as in English.
abstract final class GlmCut {
  static const double card = 18, button = 13, badge = 10, chip = 6;

  static BorderRadiusDirectional radius(double cut) => BorderRadiusDirectional.only(
        topStart: Radius.circular(cut),
        bottomEnd: Radius.circular(cut),
        topEnd: Radius.circular(cut * .22),
        bottomStart: Radius.circular(cut * .22),
      );

  static BeveledRectangleBorder shape(double cut, {BorderSide side = BorderSide.none}) => BeveledRectangleBorder(side: side, borderRadius: radius(cut));
}

/// Clips its child to the cut.
class CutClip extends StatelessWidget {
  const CutClip({super.key, required this.child, this.cut = GlmCut.card});

  final Widget child;
  final double cut;

  @override
  Widget build(BuildContext context) =>
      ClipPath(clipper: ShapeBorderClipper(shape: GlmCut.shape(cut), textDirection: Directionality.of(context)), child: child);
}

/// The gold line along the upper cut: the signature's detail. Bright on the screen's main card, faint on the others.
class CutNotch extends CustomPainter {
  CutNotch({required this.cut, required this.color, required this.rtl, this.width = 2.6});

  final double cut, width;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size s) {
    // A line parallel to the bevel, a little inside it, shorter than it.
    // On the line x + y = cut + inset, from a little off one edge to a little off the other.
    final k = cut + width * 2.2, e = width * 1.9;
    Offset at(double x, double y) => Offset(rtl ? s.width - x : x, y);
    canvas.drawLine(
      at(e, k - e),
      at(k - e, e),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(CutNotch old) => old.color != color || old.cut != cut || old.rtl != rtl;
}

/// A sweep of light crossing the child every few seconds (the main button, the hero card): the sheen of a trophy.
/// Still when the phone asks for less motion.
class Shine extends StatefulWidget {
  const Shine({super.key, required this.child, this.enabled = true, this.period = const Duration(milliseconds: 4200), this.strength = .28, this.clip});

  final Widget child;
  final bool enabled;
  final Duration period;
  final double strength;

  /// The cut the light is held inside (none: a rectangle).
  final double? clip;

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.enabled && !still && Ambient.on) {
      if (!_c.isAnimating) _c.repeat();
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
    if (!widget.enabled || !_c.isAnimating) return widget.child;
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: _clip(AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              // The light crosses in the first third of the period, then rests.
              final t = (_c.value * 3).clamp(0.0, 1.0);
              if (t <= 0 || t >= 1) return const SizedBox();
              final x = -1.6 + t * 3.2;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(x - .5, -1),
                    end: Alignment(x + .5, 1),
                    colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: widget.strength), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              );
            },
          )),
        ),
      ),
    ]);
  }

  Widget _clip(Widget w) => widget.clip == null ? w : CutClip(cut: widget.clip!, child: w);
}

/// A broadcast slab: the section's title on a gold slanted tab, a hairline running on to the edge.
class BroadcastTitle extends StatelessWidget {
  const BroadcastTitle(this.title, {super.key, this.icon, this.trailing});

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, box) => Row(children: [
      // The tab takes what its title needs, up to most of the row; the hairline the rest.
      ConstrainedBox(constraints: BoxConstraints(maxWidth: box.maxWidth * (trailing == null ? .8 : .6)), child: Container(
        height: 28,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 16, 0),
        decoration: ShapeDecoration(
          shape: GlmCut.shape(9),
          gradient: LinearGradient(colors: [p.goldLight, p.gold, p.goldDark], stops: const [0, .5, 1]),
          shadows: [BoxShadow(color: p.gold.withValues(alpha: .25), blurRadius: 12, spreadRadius: -4)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: p.onGold), const SizedBox(width: 6)],
          Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.onGold, fontWeight: FontWeight.w800, fontSize: 14.5, height: 1.1))),
        ]),
      )),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          height: 1.4,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [p.gold.withValues(alpha: .55), p.gold.withValues(alpha: 0)]).let(Directionality.of(context))),
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 8), trailing!],
    ]));
  }
}

extension on LinearGradient {
  /// The hairline fades toward the reading end.
  LinearGradient let(TextDirection d) => d == TextDirection.rtl ? LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: colors) : this;
}

/// A screen's hero (the coach on the stadium, the next match, the final score) in the Legend Cut: a lit edge, a glow
/// under it, the gold line, and the sheen passing now and then.
class HeroFrame extends StatelessWidget {
  const HeroFrame({super.key, required this.child, this.edge, this.glow, this.gradient, this.cut = 24});

  final Widget child;
  final Color? edge, glow;
  final Gradient? gradient;
  final double cut;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final e = edge ?? p.gold;
    return CustomPaint(
      foregroundPainter: CutNotch(cut: cut, rtl: Directionality.of(context) == TextDirection.rtl, color: p.goldLight, width: 3),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: GlmCut.shape(cut, side: BorderSide(color: e.withValues(alpha: .55), width: 1.2)),
          gradient: gradient,
          shadows: [BoxShadow(color: (glow ?? e).withValues(alpha: .22), blurRadius: 30, spreadRadius: -8, offset: const Offset(0, 10))],
        ),
        child: CutClip(cut: cut, child: Shine(strength: .12, period: const Duration(milliseconds: 7000), child: child)),
      ),
    );
  }
}

/// The text fields' border in the Legend Cut.
class CutInputBorder extends InputBorder {
  const CutInputBorder({super.borderSide = const BorderSide(), this.cut = GlmCut.button});

  final double cut;

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  CutInputBorder copyWith({BorderSide? borderSide}) => CutInputBorder(borderSide: borderSide ?? this.borderSide, cut: cut);

  @override
  ShapeBorder scale(double t) => CutInputBorder(borderSide: borderSide.scale(t), cut: cut * t);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => GlmCut.shape(cut).getInnerPath(rect.deflate(borderSide.width), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => GlmCut.shape(cut).getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {double? gapStart, double gapExtent = 0, double gapPercentage = 0, TextDirection? textDirection}) =>
      GlmCut.shape(cut, side: borderSide).paint(canvas, rect, textDirection: textDirection);
}
