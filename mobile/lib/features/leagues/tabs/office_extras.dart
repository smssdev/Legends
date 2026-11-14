import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/gen/models.g.dart' as api;
import '../../../core/api/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/tokens.g.dart';
import '../../../ui/widgets/async_view.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_card.dart';
import '../../club/club_data.dart';
import '../../notifications/notifications_screen.dart' show notificationSettingsProvider;
import '../page.dart';
import '../widgets.dart' show when;

/// [Sprint 64 F3] «Since your last visit» from the server (ClubBoard.since): cards flipped by a tap (the newest
/// result, the position before the unseen matches and now, the offers waiting), shown while those matches are unseen,
/// so once for each absence.
class SinceVisitCard extends StatefulWidget {
  const SinceVisitCard({super.key, required this.since});

  final api.ClubBoardSince since;

  @override
  State<SinceVisitCard> createState() => _SinceVisitCardState();
}

class _SinceVisitCardState extends State<SinceVisitCard> {
  int _at = 0;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = widget.since;
    final faces = ['result', if (s.position.now != null) 'position', if (s.offers > 0) 'offers'];
    final face = faces[_at % faces.length];
    final before = s.position.before, now = s.position.now;
    final moved = before != null && now != null ? before - now : 0;
    final (String big, String line) = switch (face) {
      'result' => (
        '${s.last.homeGoals} - ${s.last.awayGoals}',
        '${s.last.result > 0 ? l.resultWin : (s.last.result < 0 ? l.resultLoss : l.resultDraw)} · ${s.last.home.name} - ${s.last.away.name}',
      ),
      'position' => ('${before ?? '-'} → $now', moved > 0 ? l.sinceUp(moved) : (moved < 0 ? l.sinceDown(-moved) : l.sinceSame)),
      _ => ('${s.offers}', l.sinceOffers),
    };
    return Semantics(
      button: true,
      label: l.sinceTitle,
      child: GlmCard(
        gold: true,
        onTap: faces.length > 1 ? () => setState(() => _at++) : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Column(
            key: ValueKey(face),
            children: [
              Text(
                '${l.sinceTitle} · ${(_at % faces.length) + 1}/${faces.length}',
                style: glmText(GlmType.caption, color: context.palette.textMuted),
              ),
              Text(
                big,
                textDirection: TextDirection.ltr,
                style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, color: context.glm.goldText),
              ),
              Text(line, textAlign: TextAlign.center, style: glmText(GlmType.body)),
              if (faces.length > 1) Text(l.sinceFlip, style: glmText(GlmType.caption, color: context.palette.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// [Sprint 64 F11] The players' milestones with the club, until the coach has seen them (the message stays in the inbox).
class MilestonesCard extends ConsumerWidget {
  const MilestonesCard({super.key, required this.items, required this.leagueId});

  final List<api.PlayerMilestone> items;
  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    String line(api.PlayerMilestone m) => switch (m.kind) {
      'goals' => l.milestoneGoals(m.value),
      'matches' => l.milestoneMatches(m.value),
      _ => m.value == 1 ? l.milestoneMotmFirst : l.milestoneMotm(m.value),
    };
    return GlmCard(
      gold: true,
      child: Row(
        children: [
          const GlmStateArt('celebrate', size: 44),
          const SizedBox(width: GlmSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in items)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: m.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' · ${line(m)}'),
                      ],
                    ),
                    style: glmText(GlmType.body),
                  ),
              ],
            ),
          ),
          GlmButton(
            label: l.milestoneGreat,
            variant: GlmButtonVariant.quiet,
            onPressed: () async {
              await tryAction(context, () => ref.read(apiProvider).post('/leagues/$leagueId/team/milestones/seen'));
              ref.invalidate(clubSummaryProvider(leagueId));
            },
          ),
        ],
      ),
    );
  }
}

/// [Sprint 64 F4] Nothing waits: «all ready», the next match's time, and a button that turns the «match soon»
/// notifications on when they are off (the existing kind).
class AllReadyCard extends ConsumerWidget {
  const AllReadyCard({super.key, this.matchAt});

  final DateTime? matchAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final settings = ref.watch(notificationSettingsProvider).value;
    final off = settings != null && !(settings.kinds.where((k) => k.kind == 'match_soon').firstOrNull?.on_ ?? true);
    return GlmCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const GlmStateArt('celebrate', size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.allClear, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (matchAt != null)
                  Text(l.nextMatchAt(when(context, matchAt!.toLocal())), style: glmText(GlmType.caption, color: context.palette.textMuted)),
              ],
            ),
          ),
          if (off)
            GlmButton(
              label: l.remindMe,
              variant: GlmButtonVariant.outline,
              onPressed: () async {
                await tryAction(
                  context,
                  () => ref.read(apiProvider).put('/notifications', {
                    'kinds': {'match_soon': true},
                  }),
                );
                ref.invalidate(notificationSettingsProvider);
              },
            ),
        ],
      ),
    );
  }
}
