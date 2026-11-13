import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';
import '../tokens.g.dart';
import 'cut.dart';
import 'glm_button.dart';

/// [Sprint 16] One way for every screen to wait, fail and show: a spinner, the API's message with «try again», or
/// the data. Keeps the previous data on screen while it refreshes.
/// [Sprint 54 F3] Named GlmAsync as the web's AsyncState: `skeleton` holds the place in the shape of what comes
/// (GlmSkeleton) instead of the spinner, and `isEmpty` shows the empty state (a title and a line) for an empty list.
/// AsyncView stays as its other name, for the screens written before.
class GlmAsync<T> extends StatelessWidget {
  const GlmAsync({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.skeleton,
    this.rows = 4,
    this.isEmpty,
    this.emptyTitle,
    this.emptyText,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final GlmSkeletonKind? skeleton;
  final int rows;
  final bool Function(T data)? isEmpty;
  final String? emptyTitle, emptyText;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) {
      final v = value.value as T;
      if (isEmpty?.call(v) ?? false) return _Empty(title: emptyTitle ?? L.of(context).nothingYet, text: emptyText);
      return data(v);
    }
    if (value.hasError) {
      // [Sprint 60 F9] As the site's AsyncState: the reason in a box tinted by the alarm, and «حاول مجدداً».
      final p = context.palette;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GlmSpace.lg),
          child: Semantics(
            liveRegion: true,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(horizontal: GlmSpace.lg, vertical: GlmSpace.xl),
              decoration: BoxDecoration(
                color: p.live.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(GlmRadius.xl),
                border: Border.all(color: p.live.withValues(alpha: .30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ApiError.from(value.error!).message,
                    textAlign: TextAlign.center,
                    style: context.type.body.copyWith(fontWeight: FontWeight.w700, color: p.text),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: GlmSpace.md),
                    GlmButton(label: L.of(context).retry, variant: GlmButtonVariant.quiet, onPressed: onRetry),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    // [Sprint 60 F9] Loading in the shape of what comes, rows unless the screen says (the site's AsyncState too).
    return Semantics(
      label: L.of(context).loading,
      child: GlmSkeleton(kind: skeleton ?? GlmSkeletonKind.row, count: rows),
    );
  }
}

typedef AsyncView<T> = GlmAsync<T>;

class _Empty extends StatelessWidget {
  const _Empty({required this.title, this.text});

  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(GlmSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: context.palette.textMuted),
          const SizedBox(height: GlmSpace.md),
          Text(title, textAlign: TextAlign.center, style: context.type.title),
          if (text != null) ...[const SizedBox(height: GlmSpace.xs), Text(text!, textAlign: TextAlign.center, style: context.type.caption)],
        ],
      ),
    ),
  );
}

/// [Sprint 54 F3] The web's Skeleton: lines of text, cards, rows or the board's hero in the shape of what comes, a soft
/// light passing over them (still with reduced motion). Hidden from screen readers; GlmAsync says it is loading.
enum GlmSkeletonKind { line, card, row, hero }

class GlmSkeleton extends StatefulWidget {
  const GlmSkeleton({super.key, this.kind = GlmSkeletonKind.line, this.count = 3});

  final GlmSkeletonKind kind;
  final int count;

  @override
  State<GlmSkeleton> createState() => _GlmSkeletonState();
}

class _GlmSkeletonState extends State<GlmSkeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (h, r) = switch (widget.kind) {
      GlmSkeletonKind.line => (16.0, GlmRadius.sm),
      GlmSkeletonKind.row => (GlmTouch.web, GlmRadius.lg),
      GlmSkeletonKind.card => (160.0, GlmRadius.xl),
      GlmSkeletonKind.hero => (224.0, GlmRadius.xxl),
    };
    // [Sprint 61 F5] The shimmer repaints only the skeleton.
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 1; i <= widget.count; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: GlmSpace.sm),
                  child: FractionallySizedBox(
                    widthFactor: widget.kind == GlmSkeletonKind.line ? (100 - (i * 17) % 40) / 100 : 1,
                    child: Container(
                      height: h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r),
                        gradient: LinearGradient(
                          begin: Alignment(-3 + _c.value * 4, 0),
                          end: Alignment(-1 + _c.value * 4, 0),
                          colors: [p.surfaceSunk, p.surfaceRaised, p.surfaceSunk],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [Sprint 54 F3] The web's PageTitle: the screen's title on the headline role with the gold mark under it, a line
/// under that, and the screen's actions at its end.
class GlmPageTitle extends StatelessWidget {
  const GlmPageTitle(this.title, {super.key, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: GlmSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.type.headline, semanticsLabel: title),
                const SizedBox(height: GlmSpace.xs),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GlmRadius.pill),
                    gradient: LinearGradient(colors: [p.gold, p.gold.withValues(alpha: 0)]),
                  ),
                ),
                if (subtitle != null) ...[const SizedBox(height: GlmSpace.sm), Text(subtitle!, style: context.type.caption)],
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: GlmSpace.sm), a],
        ],
      ),
    );
  }
}

/// A section's title in a list, as the web's h2.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
    // [2026-11-06] The broadcast slab, the game's section mark on every screen.
    child: BroadcastTitle(text, trailing: trailing),
  );
}

/// [2026-11-06] The game's own wait: a ball spinning under a floodlight's glow, its shadow breathing on the grass.
class GlmLoader extends StatefulWidget {
  const GlmLoader({super.key, this.size = 46});

  final double size;

  @override
  State<GlmLoader> createState() => _GlmLoaderState();
}

class _GlmLoaderState extends State<GlmLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final ball = Icon(Icons.sports_soccer_rounded, size: widget.size, color: p.text);
    return RepaintBoundary(
      child: Semantics(
        label: '…',
        child: SizedBox(
          width: widget.size * 2,
          height: widget.size * 1.9,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final t = still ? 0.0 : _c.value;
              // A small bounce: up and down twice a turn.
              final hop = still ? 0.0 : (1 - (2 * ((t * 2) % 1) - 1).abs()) * widget.size * .28;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: widget.size * 1.8,
                    height: widget.size * 1.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [p.goldLight.withValues(alpha: .18), p.goldLight.withValues(alpha: 0)]),
                    ),
                  ),
                  Positioned(
                    bottom: widget.size * .12,
                    child: Container(
                      width: widget.size * (.75 - hop / widget.size * .6),
                      height: widget.size * .14,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.size), color: p.shade.withValues(alpha: .45)),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -hop - widget.size * .1),
                    child: Transform.rotate(angle: t * 6.283185307179586, child: ball),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
