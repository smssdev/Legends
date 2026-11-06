import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// [Sprint 15 F2, redesigned 2026-11-06] A card: a raised surface lit from the top (a soft gradient and a hairline of
/// light on its upper edge), one deep shadow, and a gold edge and glow when it is the screen's main object.
class GlmCard extends StatelessWidget {
  const GlmCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.gold = false, this.onTap, this.color, this.accent});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool gold;
  final VoidCallback? onTap;
  final Color? color;

  /// A club's or a state's colour washed into the card's corner (a club card, a live match, a warning).
  final Color? accent;

  static const double radius = 20;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final day = context.glm.day;
    final r = BorderRadius.circular(radius);
    final base = color ?? (day ? p.panel : p.surface);
    final top = Color.lerp(base, day ? Colors.white : p.surfaceRaised, day ? .6 : .55)!;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, base]),
        border: Border.all(color: gold ? p.gold.withValues(alpha: .55) : (day ? p.surfaceRaised : Colors.white.withValues(alpha: .07))),
        boxShadow: [
          BoxShadow(color: p.shade.withValues(alpha: day ? .10 : .45), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -10),
          if (gold) BoxShadow(color: p.gold.withValues(alpha: day ? .10 : .16), blurRadius: 28, spreadRadius: -6),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
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
            child: InkWell(borderRadius: r, onTap: onTap, child: Padding(padding: padding, child: child)),
          ),
        ]),
      ),
    );
    // A card that opens something sinks a little under the finger.
    return onTap == null ? card : PressScale(child: card);
  }
}
