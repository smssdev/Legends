import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/span.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/tokens.g.dart';
import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/console.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_card.dart';
import '../../club/club_data.dart';

// [Sprint 60 F3] The office as the approved draft draws it (docs/design/legends-ui/landscape/Office.html): the next match
// first, with its countdown and its three actions; the clocks under it; the table around my place beside it on a wide
// screen; and what waits for the coach, a list of its own. One screen, no page to scroll on a landscape phone.

/// The next match: both crests, the countdown between them, and the three ways to prepare it.
class OfficeNextMatch extends StatelessWidget {
  const OfficeNextMatch({super.key, required this.s, required this.leagueId});

  final ClubSummary s;
  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final base = '/leagues/$leagueId';
    final next = s.next;
    final live = s.matchStatus == 'live' && s.matchId != null;
    Widget side(String name, String code, String? crest) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClubCrest(url: crest, name: code, size: 44),
          const SizedBox(height: GlmSpace.xs),
          Text(name, maxLines: 2, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: context.type.body),
        ],
      ),
    );
    return GlmCard(
      gold: true,
      padding: const EdgeInsets.all(GlmSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [l.nextMatch, if (s.round != null) l.round(s.round!), if (s.venue != null) s.venue == 'away' ? l.away : l.home].join(' · '),
            style: context.type.caption,
          ),
          const SizedBox(height: GlmSpace.sm),
          if (next == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: GlmSpace.lg),
              child: Text(l.noNextMatch, textAlign: TextAlign.center, style: context.type.bodyLg),
            )
          else
            Row(
              children: [
                side(s.club.name, s.club.code, s.club.crestUrl),
                live
                    ? Text(l.liveNow, style: context.type.numbers(context.type.display).copyWith(color: p.live))
                    : OfficeClock(
                        at: s.matchAt,
                        style: context.type.numbers(context.type.display).copyWith(color: p.gold),
                      ),
                side(next.name, next.code, next.crestUrl),
              ],
            ),
          const SizedBox(height: GlmSpace.md),
          if (live)
            GlmButton(label: l.watchLive, block: true, onPressed: () => context.push('/match/${s.matchId}'))
          else
            Row(
              children: [
                Expanded(
                  flex: 13,
                  child: GlmButton(label: l.lineup, block: true, onPressed: () => context.push('$base/lineup')),
                ),
                const SizedBox(width: GlmSpace.xs),
                Expanded(
                  flex: 10,
                  child: GlmButton(
                    label: l.tactics,
                    variant: GlmButtonVariant.quiet,
                    block: true,
                    onPressed: () => context.push('$base/tactics'),
                  ),
                ),
                const SizedBox(width: GlmSpace.xs),
                Expanded(
                  flex: 10,
                  child: GlmButton(
                    label: l.opponentReport,
                    variant: GlmButtonVariant.quiet,
                    block: true,
                    onPressed: next == null ? null : () => context.push('$base/spy'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The clocks running for the club (the server's timers): training, the stadium's works, the market's renewal, the
/// scout, today's coins; each to the second.
class OfficeCounters extends StatelessWidget {
  const OfficeCounters({super.key, required this.s, required this.leagueId});

  final ClubSummary s;
  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final base = '/leagues/$leagueId';
    final rows = [
      for (final t in s.timers)
        switch (t.kind) {
          'training' => (Icons.fitness_center_rounded, l.training, t.at, '$base/training'),
          'stadium' => (Icons.stadium_rounded, l.stadiumWorks, t.at, '$base/stadium'),
          'market' => (Icons.storefront_rounded, l.marketRenews, t.at, '$base/market'),
          'scout' => (Icons.travel_explore_rounded, l.scout, t.at, '$base/scout'),
          'daily' => (Icons.redeem_rounded, t.at == null ? l.dailyReady : l.claimDaily, t.at, '/wallet'),
          _ => null,
        },
    ].nonNulls.toList();
    return GlmCard(
      padding: const EdgeInsets.symmetric(horizontal: GlmSpace.md, vertical: GlmSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlmSectionTitle(l.counters),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final (icon, label, at, path) in rows)
                  InkWell(
                    onTap: () => context.push(path),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: GlmTouch.web),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: p.gold),
                          const SizedBox(width: GlmSpace.sm),
                          Expanded(
                            child: Text(label, style: context.type.caption.copyWith(color: p.text)),
                          ),
                          if (at != null)
                            OfficeClock(
                              at: at,
                              style: context.type.numbers(context.type.body).copyWith(color: p.gold),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The table around my place (the board's top lines, mine lit).
class OfficeTable extends StatelessWidget {
  const OfficeTable({super.key, required this.s, required this.leagueId});

  final ClubSummary s;
  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return GlmCard(
      padding: const EdgeInsets.symmetric(horizontal: GlmSpace.md, vertical: GlmSpace.sm),
      onTap: () => context.go('/leagues/$leagueId?tab=matches'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlmSectionTitle(l.leagueTable),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final r in s.top)
                  Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: GlmSpace.sm),
                    decoration: BoxDecoration(
                      color: r.mine ? p.gold.withValues(alpha: .14) : null,
                      borderRadius: BorderRadius.circular(GlmRadius.md),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 24, child: Text('${r.position}', style: context.type.numbers(context.type.body))),
                        Expanded(
                          child: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            style: context.type.body.copyWith(fontWeight: r.mine ? FontWeight.w800 : null),
                          ),
                        ),
                        Text('${r.points}', style: context.type.numbers(context.type.body).copyWith(color: p.gold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A time to come, ticking: hh:mm:ss under a day, then in words by its two largest units (core/span.dart).
class OfficeClock extends StatefulWidget {
  const OfficeClock({super.key, required this.at, required this.style});

  final DateTime? at;
  final TextStyle style;

  @override
  State<OfficeClock> createState() => _OfficeClockState();
}

class _OfficeClockState extends State<OfficeClock> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final at = widget.at;
    if (at == null) return const SizedBox.shrink();
    final left = at.difference(DateTime.now());
    // Its time has come (the match about to start): the two sides face each other.
    if (left.isNegative) return Text('VS', style: widget.style, textDirection: TextDirection.ltr);
    if (left.inDays >= 1) {
      return Text(
        spanText(L.of(context), left),
        style: context.type.body.copyWith(color: widget.style.color, fontWeight: FontWeight.w800),
      );
    }
    String two(int n) => '$n'.padLeft(2, '0');
    return Text(
      '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}',
      style: widget.style,
      textDirection: TextDirection.ltr,
    );
  }
}
