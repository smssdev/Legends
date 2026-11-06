import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';
import 'cut.dart';
import 'glm_button.dart';

/// [Sprint 16] One way for every screen to wait, fail and show: a spinner, the API's message with «try again», or
/// the data. Keeps the previous data on screen while it refreshes.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) return data(value.value as T);
    if (value.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 40, color: context.palette.textMuted),
            const SizedBox(height: 10),
            Text(ApiError.from(value.error!).message, textAlign: TextAlign.center, style: TextStyle(color: context.palette.textSoft)),
            if (onRetry != null) ...[const SizedBox(height: 14), GlmButton(label: L.of(context).retry, variant: GlmButtonVariant.quiet, onPressed: onRetry)],
          ]),
        ),
      );
    }
    return const Center(child: GlmLoader());
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
    return Semantics(
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
            return Stack(alignment: Alignment.center, children: [
              Container(
                width: widget.size * 1.8,
                height: widget.size * 1.8,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [p.goldLight.withValues(alpha: .18), p.goldLight.withValues(alpha: 0)])),
              ),
              Positioned(
                bottom: widget.size * .12,
                child: Container(
                  width: widget.size * (.75 - hop / widget.size * .6),
                  height: widget.size * .14,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.size), color: p.shade.withValues(alpha: .45)),
                ),
              ),
              Transform.translate(offset: Offset(0, -hop - widget.size * .1), child: Transform.rotate(angle: t * 6.283185307179586, child: ball)),
            ]);
          },
        ),
      ),
    );
  }
}
