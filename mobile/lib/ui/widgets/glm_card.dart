import 'package:flutter/material.dart';

import '../theme.dart';
import 'cut.dart';
import 'motion.dart';

/// [Sprint 15 F2, redesigned 2026-11-06] A card in the Legend Cut (cut.dart): a raised surface lit from the top, one
/// deep shadow, the gold line on its upper cut, and a gold edge, glow and a passing sheen when it is the screen's main
/// object.
class GlmCard extends StatelessWidget {
  const GlmCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.gold = false, this.onTap, this.color, this.accent, this.shine});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool gold;
  final VoidCallback? onTap;
  final Color? color;

  /// A club's or a state's colour washed into the card's corner (a club card, a live match, a warning).
  final Color? accent;

  /// The passing sheen; on by default for a gold card.
  final bool? shine;

  static const double radius = GlmCut.card;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final day = context.glm.day;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final base = color ?? (day ? p.panel : p.surface);
    final top = Color.lerp(base, day ? Colors.white : p.surfaceRaised, day ? .6 : .55)!;
    final shape = GlmCut.shape(radius, side: BorderSide(color: gold ? p.gold.withValues(alpha: .6) : (day ? p.surfaceRaised : Colors.white.withValues(alpha: .08))));
    Widget card = DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, base]),
        shadows: [
          BoxShadow(color: p.shade.withValues(alpha: day ? .10 : .45), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -10),
          if (gold) BoxShadow(color: p.gold.withValues(alpha: day ? .10 : .18), blurRadius: 28, spreadRadius: -6),
        ],
      ),
      child: CutClip(
        child: Stack(children: [
          if (accent != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(center: const AlignmentDirectional(1.1, -1.2).resolve(Directionality.of(context)), radius: 1.3,
                      colors: [accent!.withValues(alpha: day ? .16 : .30), accent!.withValues(alpha: 0)]),
                ),
              ),
            ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(customBorder: GlmCut.shape(radius), onTap: onTap, child: Padding(padding: padding, child: child)),
          ),
        ]),
      ),
    );
    card = CustomPaint(
      foregroundPainter: CutNotch(cut: radius, rtl: rtl, color: gold ? p.goldLight : p.gold.withValues(alpha: day ? .45 : .38)),
      child: card,
    );
    if (shine ?? gold) card = Shine(strength: .10, period: const Duration(milliseconds: 6000), clip: GlmCut.card, child: card);
    // A card that opens something sinks a little under the finger.
    return onTap == null ? card : PressScale(child: card);
  }
}
