import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../theme.dart';

/// [Sprint 50 M3, M16, M23] The landscape console's own pieces, each on its counterpart on the site (the owner, 2026-11-10:
/// the app never leaves the site's design): the card title's gold tick (main section > h2), the split screen, the two
/// teams' bar of the report, the field with its label beside it, and the 3D models (tools/models/make_models.py).

/// A card's title with the site's small gold tick before it.
class GlmSectionTitle extends StatelessWidget {
  const GlmSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Container(
          width: 4,
          height: 17,
          decoration: BoxDecoration(color: p.gold, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// [Sprint 50 M3] A screen split side by side at a ratio (50:50, 60:40, 30:70, 70:30): the console's main area and its
/// inspector. On a narrow screen (a tablet held the other way never happens: the game is landscape only, but a small
/// window may) the two stack.
class GlmSplitLayout extends StatelessWidget {
  const GlmSplitLayout({
    super.key,
    required this.start,
    required this.end,
    this.ratio = (50, 50),
    this.gap = 8,
    this.padding = const EdgeInsets.all(8),
  });

  final Widget start, end;
  final (int, int) ratio;
  final double gap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: start),
              SizedBox(height: gap),
              Expanded(child: end),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: ratio.$1, child: start),
            SizedBox(width: gap),
            Expanded(flex: ratio.$2, child: end),
          ],
        );
      },
    ),
  );
}

/// [Sprint 50 M16] The report's bar for one figure: your side in mint from the middle to the start, the other in orange
/// to the end, each number at its edge and the figure's name in the middle (the board's GlmDualCompareBar).
class GlmDualCompareBar extends StatelessWidget {
  const GlmDualCompareBar({super.key, required this.label, required this.mine, required this.theirs, this.mineText, this.theirsText});

  final String label;
  final num mine, theirs;
  final String? mineText, theirsText;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = mine + theirs;
    final a = total == 0 ? .5 : mine / total;
    const number = TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 15);
    Widget bar(double share, Color colour, AlignmentGeometry from) => Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(color: p.surfaceRaised, borderRadius: BorderRadius.circular(4)),
        alignment: from,
        child: FractionallySizedBox(
          widthFactor: share.clamp(0, 1).toDouble(),
          child: Container(
            decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
    return Semantics(
      label: '$label: ${mineText ?? mine} - ${theirsText ?? theirs}',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(mineText ?? '$mine', textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: number),
          ),
          bar(a.toDouble(), p.brandLight, AlignmentDirectional.centerEnd),
          SizedBox(
            width: 86,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textMuted, fontSize: 12),
            ),
          ),
          bar(1 - a.toDouble(), p.warning, AlignmentDirectional.centerStart),
          SizedBox(
            width: 38,
            child: Text(theirsText ?? '$theirs', textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: number),
          ),
        ],
      ),
    );
  }
}

/// [Sprint 50 M3] A field with its label beside it, not above: the console keeps its height when the keyboard is up.
class GlmCompactField extends StatelessWidget {
  const GlmCompactField({super.key, required this.label, required this.child, this.labelWidth = 110});

  final String label;
  final Widget child;
  final double labelWidth;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: labelWidth,
        child: Text(label, style: TextStyle(color: context.palette.textMuted, fontSize: 13)),
      ),
      const SizedBox(width: 8),
      Expanded(child: child),
    ],
  );
}

/// [Sprint 50 M3] The floating input sheet: a short sheet that opens on the screen's upper half above the keyboard, so
/// the scene behind it stays in sight (the chat's composer, an amount to offer, a bid).
Future<T?> showCompactInputSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext) builder}) {
  final p = context.palette;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: .45),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Material(
              color: p.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: p.gold.withValues(alpha: .3)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [GlmSectionTitle(title), const SizedBox(height: 10), builder(context)],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, a, _, child) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -.06), end: Offset.zero).animate(a),
        child: child,
      ),
    ),
  );
}

/// [Sprint 50 M23] A 3D model of ours (mobile/assets/models, made by tools/models/make_models.py), turning slowly and
/// turned by the finger. Under widget tests, with reduced motion (no turning) or where the phone has no web view, the
/// drawn [fallback] stands in its place, so the screen never waits on it.
class GlmModel3D extends StatelessWidget {
  const GlmModel3D({super.key, required this.model, required this.label, required this.fallback, this.turn = true, this.orbit});

  /// The file's name in assets/models, without .glb.
  final String model;
  final String label;
  final Widget fallback;
  final bool turn;

  /// Where the camera looks from ("0deg 75deg 105%"), the model's default otherwise.
  final String? orbit;

  /// Off under the widget tests (no web view there).
  static bool enabled = !Platform.environment.containsKey('FLUTTER_TEST');

  @override
  Widget build(BuildContext context) {
    if (!enabled || !(Platform.isAndroid || Platform.isIOS)) return Semantics(label: label, child: fallback);
    final still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: label,
      child: ModelViewer(
        src: 'assets/models/$model.glb',
        alt: label,
        autoRotate: turn && !still,
        autoRotateDelay: 0,
        rotationPerSecond: '18deg',
        cameraControls: true,
        disableZoom: true,
        cameraOrbit: orbit,
        backgroundColor: Colors.transparent,
        shadowIntensity: .6,
        exposure: 1.1,
        interactionPrompt: InteractionPrompt.none,
        loading: Loading.eager,
      ),
    );
  }
}
