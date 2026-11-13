import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

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

/// [Sprint 61 F2] A model of ours (tools/models: made by make_models.py, turned once around by render_spins.cjs) as
/// pictures, not a web view: a strip of 24 frames (`assets/models/<model>_spin_<size>.webp`) turned slowly, each frame
/// fading into the next, and turned by the finger. Under widget tests or with reduced motion it stands still (and the
/// drawn [fallback] holds its place until the strip is read).
class GlmModelSpin extends StatefulWidget {
  const GlmModelSpin({super.key, required this.model, required this.label, required this.fallback, this.turn = true});

  /// The model's name in assets/models (its strips are `<model>_spin_512.webp` and `_256.webp`).
  final String model;
  final String label;
  final Widget fallback;
  final bool turn;

  static const frames = 24;

  /// Frames a second while it turns by itself (30° a second).
  static const pace = 2.0;

  /// Off under the widget tests (their clock never reads the strip): the fallback stands.
  static bool enabled = !Platform.environment.containsKey('FLUTTER_TEST');

  @override
  State<GlmModelSpin> createState() => _GlmModelSpinState();
}

class _GlmModelSpinState extends State<GlmModelSpin> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double _at = 0;
  bool _held = false;
  ui.Image? _strip;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  int? _size;

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (!_held) setState(() => _at = (_at + dt * GlmModelSpin.pace) % GlmModelSpin.frames);
  }

  void _read(int size) {
    if (_size == size) return;
    _size = size;
    _stop();
    final stream = AssetImage('assets/models/${widget.model}_spin_$size.webp').resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      if (mounted) setState(() => _strip = info.image);
    });
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _stop() {
    if (_stream != null && _listener != null) _stream!.removeListener(_listener!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.of(context).disableAnimations;
    if (widget.turn && !still && GlmModelSpin.enabled) {
      if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!GlmModelSpin.enabled) return Semantics(label: widget.label, child: widget.fallback);
    return Semantics(
      label: widget.label,
      image: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = math.min(box.maxWidth, box.maxHeight) * MediaQuery.devicePixelRatioOf(context);
          _read(side > 256 ? 512 : 256);
          final strip = _strip;
          return GestureDetector(
            onHorizontalDragStart: (_) => _held = true,
            // One frame for every 16 points the finger moves.
            onHorizontalDragUpdate: (d) => setState(() => _at = (_at - d.delta.dx / 16) % GlmModelSpin.frames),
            onHorizontalDragEnd: (_) => _held = false,
            child: strip == null
                ? widget.fallback
                : RepaintBoundary(
                    child: CustomPaint(size: box.biggest, painter: _SpinPainter(strip, _at)),
                  ),
          );
        },
      ),
    );
  }
}

class _SpinPainter extends CustomPainter {
  _SpinPainter(this.strip, this.at);

  final ui.Image strip;
  final double at;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = strip.height.toDouble();
    final side = math.min(size.width, size.height);
    final dst = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final i = at.floor() % GlmModelSpin.frames;
    final next = (i + 1) % GlmModelSpin.frames;
    final mix = at - at.floor();
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(strip, Rect.fromLTWH(i * frame, 0, frame, frame), dst, paint);
    // The next frame fading in: the turn reads as smooth between the 24 pictures.
    if (mix > 0.01) {
      canvas.drawImageRect(strip, Rect.fromLTWH(next * frame, 0, frame, frame), dst, paint..color = Colors.black.withValues(alpha: mix));
    }
  }

  @override
  bool shouldRepaint(_SpinPainter old) => old.at != at || old.strip != strip;
}
