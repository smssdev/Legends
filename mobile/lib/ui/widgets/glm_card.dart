import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.g.dart';

/// [Sprint 15 F2] The web's UiCard: a raised surface with a soft line and one shadow, optionally gold-edged.
class GlmCard extends StatelessWidget {
  const GlmCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.gold = false, this.onTap, this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool gold;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(GlmSize.radiusXxl);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? (context.glm.day ? p.panel : p.surface),
        borderRadius: radius,
        border: Border.all(color: gold ? p.gold.withValues(alpha: .45) : p.surfaceRaised),
        boxShadow: [BoxShadow(color: p.shade.withValues(alpha: context.glm.day ? .10 : .35), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -18)],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: radius, onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}
