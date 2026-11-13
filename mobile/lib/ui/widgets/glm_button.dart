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
  const GlmButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GlmButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.block = false,
  });

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
    final (Color fg, Color flat, BorderSide side) = switch (variant) {
      GlmButtonVariant.primary => (p.onGold, p.gold, BorderSide.none),
      GlmButtonVariant.brand => (Colors.white, p.brandDark, BorderSide.none),
      GlmButtonVariant.outline => (p.text, Colors.transparent, BorderSide(color: p.surfaceRaised, width: 1.5)),
      GlmButtonVariant.quiet => (p.text, p.surfaceRaised, BorderSide.none),
      GlmButtonVariant.danger => (Colors.white, p.live, BorderSide.none),
    };
    final child = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        else ...[
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: fg, size: 20),
              child: icon!,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            // [Sprint 60 F8] The label wraps to a second line before anything is cut («وقت مستقطع», not «وقت مستـ…»).
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge?.copyWith(color: fg, fontSize: 16, height: 1.2),
            ),
          ),
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
              color: flat,
              shape: GlmCut.shape(GlmCut.button, side: side),
              // [Sprint 47] The approved design's gold button stands on its darker edge, like a game's key.
              shadows: enabled && variant == GlmButtonVariant.primary
                  ? [BoxShadow(color: p.goldDark, offset: const Offset(0, 3))]
                  : enabled && variant == GlmButtonVariant.brand
                  ? [BoxShadow(color: p.shade.withValues(alpha: .35), offset: const Offset(0, 3))]
                  : null,
            ),
            child: CutClip(
              cut: GlmCut.button,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: GlmCut.shape(GlmCut.button),
                  onTap: enabled
                      ? () {
                          HapticFeedback.selectionClick();
                          GameSounds.play(Sfx.tap);
                          onPressed!();
                        }
                      : null,
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
