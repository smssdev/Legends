import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/glm_card.dart';

/// [Sprint 64 F2] «Your first steps»: three, not seven (a club, its lineup, a match), each done in the game (the
/// server's `onboarding`, never by a tap), each a way to its screen; gone once the three are done. The rest are the
/// first week's tasks (the daily tasks on the office).
class FirstSteps extends StatelessWidget {
  const FirstSteps({super.key, required this.steps, this.leagueId});

  final Map<String, bool> steps;
  final int? leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final base = leagueId == null ? null : '/leagues/$leagueId';
    final items = [
      ('club', l.firstStepClub, '/leagues'),
      ('lineup', l.firstStepLineup, base == null ? '/leagues' : '$base/lineup'),
      ('match', l.firstStepMatch, base == null ? '/leagues' : '$base/matchday'),
    ];
    final done = items.where((i) => steps[i.$1] ?? false).length;
    if (done == items.length) return const SizedBox.shrink();
    return GlmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l.firstStepsTitle} · $done/${items.length}', style: glmText(GlmType.title)),
          const SizedBox(height: GlmSpace.xs),
          for (final (key, label, path) in items)
            InkWell(
              onTap: (steps[key] ?? false) ? null : () => context.push(path),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GlmTouch.app),
                child: Row(
                  children: [
                    Icon(
                      (steps[key] ?? false) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: (steps[key] ?? false) ? p.success : context.glm.goldText,
                    ),
                    const SizedBox(width: GlmSpace.sm),
                    Expanded(
                      child: Text(label, style: glmText(GlmType.body, color: (steps[key] ?? false) ? p.textMuted : null)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
