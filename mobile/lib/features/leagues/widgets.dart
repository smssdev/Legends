import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../home/home_screen.dart' show latinDigits;
import 'models.dart';

/// [Sprint 16] Small pieces the league screens share.
String goalText(L l, ({String kind, int target})? goal) => switch (goal?.kind) {
      null => '',
      'title' => l.goalTitle,
      'survive' => l.goalSurvive(goal!.target),
      _ => l.goalPlace(goal!.target),
    };

String when(BuildContext context, DateTime at) =>
    latinDigits(DateFormat.MMMEd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(at));

/// A match in a list: the two sides with their crests, and the score or the time.
class FixtureTile extends StatelessWidget {
  const FixtureTile(this.f, {super.key, this.mine});

  final Fixture f;
  final int? mine;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ours = f.home.id == mine || f.away.id == mine;
    Widget side(Side s, {required bool end}) => Expanded(
          child: Row(mainAxisAlignment: end ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
            if (!end) ...[ClubCrest(url: s.crestUrl, name: s.code, size: 28), const SizedBox(width: 8)],
            Flexible(child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: s.id == mine ? FontWeight.w800 : FontWeight.w600, fontSize: 14))),
            if (end) ...[const SizedBox(width: 8), ClubCrest(url: s.crestUrl, name: s.code, size: 28)],
          ]),
        );
    final middle = f.finished || f.live
        ? Text('${f.homeGoals ?? 0} - ${f.awayGoals ?? 0}', textDirection: TextDirection.ltr,
            style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 20, color: f.live ? context.glm.liveText : p.text))
        : Text(f.at == null ? '—' : latinDigits(DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(f.at!)),
            style: TextStyle(color: p.textMuted, fontSize: 13, fontWeight: FontWeight.w700));
    // [Sprint 17 F2] A match under way or played opens: live, or its report afterwards.
    final open = f.matchId == null ? null : () => context.push(f.finished ? '/match/${f.matchId}/report?coach=$ours' : '/match/${f.matchId}');
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ours ? p.gold.withValues(alpha: .10) : p.surface,
        borderRadius: BorderRadius.circular(GlmSize.radiusXl),
        border: Border.all(color: ours ? p.gold.withValues(alpha: .4) : p.surfaceRaised),
      ),
      // Home on the right in Arabic, as the web's score bug (tokens.json match.homeSide).
      child: Row(children: [side(f.home, end: false), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: middle), side(f.away, end: true)]),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: open == null ? tile : InkWell(borderRadius: BorderRadius.circular(GlmSize.radiusXl), onTap: open, child: tile),
    );
  }
}

/// A club to choose: crest, name, strength and its objective.
class ClubChoice extends StatelessWidget {
  const ClubChoice({super.key, required this.club, required this.onTap, this.selected = false});

  final ClubCardData club;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Material(
      color: selected ? p.gold.withValues(alpha: .14) : p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlmSize.radiusXl), side: BorderSide(color: selected ? p.gold : p.surfaceRaised, width: selected ? 2 : 1)),
      child: InkWell(
        borderRadius: BorderRadius.circular(GlmSize.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClubCrest(url: club.crestUrl, name: club.code, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(club.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text([l.strength(club.strength ~/ 100), if (club.goal != null) goalText(l, club.goal)].join(' · '), style: TextStyle(color: p.textMuted, fontSize: 12)),
              ]),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: p.gold),
          ]),
        ),
      ),
    );
  }
}
