import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/widgets.dart' show when;
import '../social/social_data.dart';
import 'match_data.dart';

/// [Sprint 64 F6] A league match before its whistle (it opens at the lock, five minutes before): the waiting room. The
/// two clubs and their coaches, the league members' predictions of this match (the predictions page's own split), the
/// kick-off time, and the chat a tap away. The live screen drops it by itself at the whistle.
class WaitingRoom extends ConsumerWidget {
  const WaitingRoom({super.key, required this.view, required this.onChat});

  final MatchView view;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final fixture = view.fixtureId;
    final split = fixture == null
        ? null
        : ref.watch(predictionsProvider(view.leagueId)).value?.matches.where((m) => m.fixtureId == fixture).firstOrNull?.split;
    final total = split == null ? 0 : split.home + split.draw + split.away;
    int pct(int n) => total == 0 ? 0 : (n * 100 / total).round();
    Widget side(MatchClub c, String key) => Expanded(
      child: Column(
        children: [
          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: glmText(GlmType.title)),
          if (view.coaches[key] case final coach?) Text(coach, style: glmText(GlmType.caption, color: p.textMuted)),
        ],
      ),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlmCard(
          gold: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.waitingRoom, style: glmText(GlmType.caption, color: p.textMuted)),
              if (view.kickoffAt case final at?)
                Text(when(context, at.toLocal()), style: glmText(GlmType.title, color: context.glm.goldText)),
              const SizedBox(height: GlmSpace.sm),
              Row(
                children: [
                  side(view.home, 'home'),
                  Text('VS', style: glmText(GlmType.headline)),
                  side(view.away, 'away'),
                ],
              ),
              if (split != null && total > 0) ...[
                const SizedBox(height: GlmSpace.sm),
                Text(l.membersPredictions, style: glmText(GlmType.caption)),
                const SizedBox(height: GlmSpace.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(GlmRadius.pill),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        if (split.home > 0)
                          Expanded(
                            flex: split.home,
                            child: ColoredBox(color: p.success),
                          ),
                        if (split.draw > 0)
                          Expanded(
                            flex: split.draw,
                            child: ColoredBox(color: p.textMuted),
                          ),
                        if (split.away > 0)
                          Expanded(
                            flex: split.away,
                            child: ColoredBox(color: p.live),
                          ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${pct(split.home)}% · ${pct(split.draw)}% · ${pct(split.away)}%',
                  textDirection: TextDirection.ltr,
                  style: glmText(GlmType.caption, fontFamily: GlmFonts.numbers),
                ),
              ],
              const SizedBox(height: GlmSpace.sm),
              GlmButton(label: l.matchChat, variant: GlmButtonVariant.quiet, onPressed: onChat),
            ],
          ),
        ),
      ),
    );
  }
}
