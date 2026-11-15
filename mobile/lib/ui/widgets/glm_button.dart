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
    this.oneLine = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlmButtonVariant variant;
  final bool loading;
  final Widget? icon;
  final bool block;

  /// [Sprint 73 D6] The label on one line whatever its length (it steps its size down): buttons side by side stay
  /// the same height.
  final bool oneLine;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    final (Color fg, Color flat, BorderSide side) = switch (variant) {
      GlmButtonVariant.primary => (p.onGold, p.gold, BorderSide.none),
      GlmButtonVariant.brand => (Colors.white, p.brandDark, BorderSide.none),
      GlmButtonVariant.outline => (p.text, Colors.transparent, BorderSide(color: p.surfaceRaised, width: 1.5)),
      GlmButtonVariant.quiet => (p.text, p.surfaceRaised, BorderSide.none),
      // [Sprint 65 F4] Navy on the red, as on the web (white on it is 3.8:1).
      GlmButtonVariant.danger => (p.onGold, p.live, BorderSide.none),
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
            // [Sprint 72 R6] And never breaks inside a word («التكتيـ/ك» on a 640 phone): it steps down to the caption's
            // size first, and only then is cut.
            child: FitLabel(
              label,
              maxLines: oneLine ? 1 : 2,
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
                          // [Sprint 64 F13] The buzz and the tap, one switch in the settings.
                          if (GameSounds.touch) {
                            HapticFeedback.selectionClick();
                            GameSounds.play(Sfx.tap);
                          }
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

/// [Sprint 72 R6] A short label (a button's, a tab's) in the room it is given: on up to [maxLines] lines broken between
/// words only, stepping its size down to [min] (the smallest text of the design, 12) before a word would break or the
/// text be cut. The shape lives here, not in the screens.
class FitLabel extends StatelessWidget {
  const FitLabel(this.text, {super.key, this.style, this.maxLines = 2, this.min = 12, this.textAlign = TextAlign.center});

  final String text;
  final TextStyle? style;
  final int maxLines;
  final double min;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final from = base.fontSize ?? 14;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final room = box.maxWidth;
        var size = from;
        if (room.isFinite) {
          double wide(String t, double s, {int? lines, double max = double.infinity}) {
            final tp = TextPainter(
              text: TextSpan(
                text: t,
                style: base.copyWith(fontSize: s),
              ),
              textDirection: direction,
              textScaler: scaler,
              maxLines: lines,
            )..layout(maxWidth: max);
            final w = lines != null && tp.didExceedMaxLines ? double.infinity : tp.width;
            tp.dispose();
            return w;
          }

          final words = text.split(RegExp(r'\s+'));
          bool fits(double s) => words.every((w) => wide(w, s) <= room) && wide(text, s, lines: maxLines, max: room).isFinite;
          while (size > min && !fits(size)) {
            size -= 1;
          }
        }
        return Text(
          text,
          maxLines: maxLines,
          textAlign: textAlign,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(fontSize: size < min ? min : size),
        );
      },
    );
  }
}
