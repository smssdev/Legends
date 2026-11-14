import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../sim/first_match_controller.dart';
import 'live_controller.dart';

/// [Sprint 64 F1] The intro match on the live screen: the assistant at the three moments the server chose (the guide's
/// words), a skip always in reach, and at the end «take a club» with the starter gift. Nothing for any other match.
class IntroCoachOverlay extends ConsumerWidget {
  const IntroCoachOverlay({super.key, required this.handle, required this.onOrders});

  final int handle;
  final VoidCallback onOrders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(introMomentsProvider.select((m) => m[handle]));
    if (moments == null || moments.isEmpty) return const SizedBox.shrink();
    final l = L.of(context);
    final s = ref.watch(introCoachProvider(handle));
    final coach = ref.read(introCoachProvider(handle).notifier);
    final match = ref.watch(liveMatchProvider(handle).select((m) => (m.minute, m.finished)));
    if (match.$2 && !s.over) scheduleMicrotask(coach.end);
    final current = IntroCoach.current(moments, s, match.$1);
    Widget bubble(String art, String title, String text, List<Widget> actions) => GlmCard(
      gold: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlmStateArt(art, size: 56),
          const SizedBox(width: GlmSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: glmText(GlmType.title, color: context.glm.goldText)),
                const SizedBox(height: GlmSpace.xs),
                Text(text, style: glmText(GlmType.body)),
                const SizedBox(height: GlmSpace.sm),
                Wrap(spacing: GlmSpace.sm, runSpacing: GlmSpace.sm, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        if (!s.over)
          PositionedDirectional(
            top: GlmSpace.sm,
            end: GlmSpace.sm,
            child: GlmButton(label: l.introSkip, variant: GlmButtonVariant.quiet, onPressed: () => unawaited(coach.end())),
          ),
        if (s.over || current != null)
          PositionedDirectional(
            start: GlmSpace.md,
            end: GlmSpace.md,
            bottom: GlmSpace.md,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: s.over
                    ? bubble('celebrate', l.introDoneTitle, l.introDoneBody, [
                        GlmButton(
                          label: l.takeClub,
                          onPressed: () async {
                            await coach.takeGift();
                            if (context.mounted) context.go('/leagues');
                          },
                        ),
                      ])
                    : bubble('welcome', current!.title, current.text, [
                        if (current.kind != 'effect')
                          GlmButton(
                            label: l.introOpenOrders,
                            onPressed: () {
                              coach.answer(current.kind);
                              onOrders();
                            },
                          ),
                        GlmButton(label: l.introOk, variant: GlmButtonVariant.quiet, onPressed: () => coach.answer(current.kind)),
                      ]),
              ),
            ),
          ),
      ],
    );
  }
}
