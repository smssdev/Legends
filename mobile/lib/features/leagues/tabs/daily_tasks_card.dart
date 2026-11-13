import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/tokens.g.dart';
import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/console.dart';
import '../../../ui/widgets/cut.dart';
import '../../../ui/widgets/game.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_card.dart';
import '../../../ui/widgets/motion.dart';
import '../../../ui/widgets/stadium.dart';
import '../../club/club_data.dart';
import '../../console/console_data.dart';
import '../models.dart';

/// [Sprint 50 M10] Today's tasks (the server's): each done one claims its coins, and the bar fills as they are done.
class DailyTasksCard extends ConsumerWidget {
  const DailyTasksCard({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final tasks = ref.watch(dailyTasksProvider(leagueId)).value;
    if (tasks == null) return const SizedBox.shrink();
    String name(String t) => switch (t) {
      'lineup' => l.taskLineup,
      'friendly' => l.taskFriendly,
      'training' => l.taskTraining,
      _ => l.taskChat,
    };
    return GlmCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlmSectionTitle(
            l.dailyTasks,
            trailing: Text(
              '${tasks.done}/${tasks.total}',
              style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: p.goldLight),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: tasks.total == 0 ? 0 : tasks.done / tasks.total,
              minHeight: 5,
              color: p.gold,
              backgroundColor: p.surfaceRaised,
            ),
          ),
          const SizedBox(height: 4),
          for (final t in tasks.tasks)
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Icon(
                    t.complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: t.complete ? p.success : p.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name(t.task),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (t.claimed)
                    Icon(Icons.done_all_rounded, size: 18, color: context.glm.successText)
                  else if (t.complete)
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: p.gold,
                        foregroundColor: p.onGold,
                        minimumSize: const Size(64, 34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(consoleRepositoryProvider).claimTask(leagueId, t.task);
                        } on ApiError catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                        ref.invalidate(dailyTasksProvider(leagueId));
                        ref.invalidate(clubSummaryProvider(leagueId));
                      },
                      child: Text(
                        '+${t.coins}',
                        style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800),
                      ),
                    )
                  else
                    Text(
                      '+${t.coins}',
                      style: TextStyle(fontFamily: GlmFonts.numbers, color: p.textMuted),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// [Sprint 46] The next match on the stadium: both clubs' crests large with their strength in a lit ring, the round, the
/// countdown, a great «VS», where it is played, and the way in (live when it plays, the match day before).
class LeagueVersus extends StatelessWidget {
  const LeagueVersus({super.key, required this.s, required this.leagueId});

  final ClubSummary s;
  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final live = s.matchId != null;
    final left = s.matchAt?.difference(DateTime.now());
    String? countdown;
    if (left != null && !left.isNegative) {
      final (d, h, m) = (left.inDays, left.inHours % 24, left.inMinutes % 60);
      countdown = d > 0 ? l.leftDaysHoursMinutes(d, h, m) : l.leftHoursMinutes(h, m);
    }
    final home = s.venue != 'away';
    final (homeSide, awaySide) = home ? (s.club, s.next ?? s.club) : (s.next ?? s.club, s.club);
    final (hs, as_) = s.strength == null
        ? (null, null)
        : home
        ? (s.strength!.$1, s.strength!.$2)
        : (s.strength!.$2, s.strength!.$1);
    Widget team(Side c, int? strength, bool mine) => Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // [Sprint 46, the polish] The crest on a soft halo of light, as under the floodlights.
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (mine ? context.palette.gold : GlmStage.accent).withValues(alpha: .35),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClubCrest(url: c.crestUrl, name: c.code, size: 84),
                ),
                if (strength != null) ...[const SizedBox(width: 10), _Ring(value: strength ~/ 100, mine: mine)],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: GlmFonts.numbers,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                color: Colors.white,
                height: 1.05,
                shadows: [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 6)],
              ),
            ),
          ],
        ),
      ),
    );
    return StadiumBackdrop(
      tint: live ? p.live : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            team(homeSide, hs, home),
            SizedBox(
              width: 190,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: ShapeDecoration(
                        shape: GlmCut.shape(10, side: BorderSide(color: Colors.white.withValues(alpha: .15))),
                        color: GlmStage.card.withValues(alpha: .9),
                      ),
                      child: Text(
                        s.round == null ? l.nextMatchShort : l.round(s.round!),
                        style: TextStyle(color: p.goldLight, fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (live)
                      Pulse(
                        child: Text(
                          l.liveBadge,
                          style: TextStyle(color: p.danger, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      )
                    else if (countdown != null)
                      Text(
                        countdown,
                        style: const TextStyle(
                          fontFamily: GlmFonts.numbers,
                          fontFamilyFallback: [GlmFonts.body],
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    Pulse(
                      min: .7,
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontFamily: GlmFonts.numbers,
                          fontWeight: FontWeight.w800,
                          fontSize: 60,
                          height: 1,
                          foreground: Paint()
                            ..shader = LinearGradient(colors: [p.goldLight, p.gold, p.goldDark])
                                .createShader(const Rect.fromLTWH(0, 0, 80, 60)),
                          shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 8)],
                        ),
                      ),
                    ),
                    Text(
                      home ? l.homeAway : l.awayGame,
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    live
                        ? GlmButton(
                            label: l.watchLive,
                            variant: GlmButtonVariant.brand,
                            icon: const Icon(Icons.play_circle_fill_rounded),
                            onPressed: () => context.push('/match/${s.matchId}'),
                          )
                        : GlmButton(
                            label: l.matchday,
                            icon: const Icon(Icons.sports_rounded),
                            onPressed: () => context.push('/leagues/$leagueId/matchday'),
                          ),
                  ],
                ),
              ),
            ),
            team(awaySide, as_, !home),
          ],
        ),
      ),
    );
  }
}

/// A club's strength as a number in a lit ring: mine in gold, theirs in blue.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.mine});

  final int value;
  final bool mine;

  @override
  Widget build(BuildContext context) => ArcGauge(value: value, size: 68, color: mine ? context.palette.gold : GlmStage.accent);
}
