import 'package:flutter/material.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/glm_background.dart';
import '../../../ui/widgets/motion.dart';
import '../../../ui/widgets/stadium.dart';

/// [Sprint 15 F3, landscape 2026-11-06] The sign-in screens' frame. Landscape: the game's emblem over the stadium at
/// night on one side, the form on the other; upright: the emblem above the form. Scrolls above the keyboard.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.lead, required this.children, this.footer});

  final String title;
  final String lead;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final form = AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, textAlign: TextAlign.center, style: text.headlineMedium),
          const SizedBox(height: 6),
          Text(lead, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          ...children,
          if (footer != null) ...[const SizedBox(height: 20), Center(child: footer!)],
        ],
      ),
    );
    return Scaffold(
      body: GlmBackground(
        wide: true,
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth > box.maxHeight) {
            return Row(children: [
              Expanded(
                flex: 5,
                child: StadiumBackdrop(
                  child: SafeArea(
                    child: Center(
                      child: FadeSlideIn(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          // A soft halo of floodlight behind the emblem.
                          DecoratedBox(
                            decoration: BoxDecoration(gradient: RadialGradient(colors: [p.gold.withValues(alpha: .22), p.gold.withValues(alpha: 0)], radius: .6)),
                            child: const Padding(padding: EdgeInsets.all(20), child: BrandMark(size: 120, stacked: true)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: FadeSlideIn(index: 2, child: form)),
                    ),
                  ),
                ),
              ),
            ]);
          }
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Center(child: BrandMark(size: 92, stacked: true)),
                    const SizedBox(height: 28),
                    form,
                  ]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
