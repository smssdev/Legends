import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens.g.dart';
import '../../core/sounds.dart';
import 'cut.dart';

enum GlmButtonVariant { primary, brand, outline, quiet, danger }

/// [Sprint 15 F2] The web's UiButton: gold (the main action), emerald, outlined, quiet and danger; at least 48 high,
/// a spinner that keeps its size while loading, and a light tap on the phone.
class GlmButton extends StatelessWidget {
  const GlmButton({super.key, required this.label, this.onPressed, this.variant = GlmButtonVariant.primary, this.loading = false, this.icon, this.block = false});

  final String label;
  final VoidCallback? onPressed;
  final GlmButtonVariant variant;
  final bool loading;
  final Widget? icon;
  final bool block;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    final (Color fg, Gradient? fill, Color? flat, BorderSide side) = switch (variant) {
      GlmButtonVariant.primary => (p.onGold, LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.goldLight, p.gold, p.goldDark], stops: const [0, .55, 1]), null, BorderSide.none),
      GlmButtonVariant.brand => (Colors.white, LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.brand, p.brandDark]), null, BorderSide.none),
      GlmButtonVariant.outline => (p.text, null, Colors.transparent, BorderSide(color: p.surfaceRaised, width: 1.5)),
      GlmButtonVariant.quiet => (p.text, null, p.surfaceSunk, BorderSide.none),
      GlmButtonVariant.danger => (Colors.white, null, p.live, BorderSide.none),
    };
    final child = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        else ...[
          if (icon != null) ...[IconTheme(data: IconThemeData(color: fg, size: 20), child: icon!), const SizedBox(width: 8)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: context.text.labelLarge?.copyWith(color: fg, fontSize: 16))),
        ],
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled || loading ? 1 : .45,
        // [2026-11-06] In the Legend Cut, and the main button carries the passing sheen.
        child: Shine(
          enabled: variant == GlmButtonVariant.primary && enabled,
          clip: GlmCut.button,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              gradient: fill, color: flat, shape: GlmCut.shape(GlmCut.button, side: side),
              shadows: fill != null && enabled ? [BoxShadow(color: (variant == GlmButtonVariant.primary ? p.gold : p.shade).withValues(alpha: .30), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -8)] : null,
            ),
            child: CutClip(
              cut: GlmCut.button,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: GlmCut.shape(GlmCut.button),
                  onTap: enabled ? () { HapticFeedback.selectionClick(); GameSounds.play(Sfx.tap); onPressed!(); } : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: GlmSize.touchMin),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
