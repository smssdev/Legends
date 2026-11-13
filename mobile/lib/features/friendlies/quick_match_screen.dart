import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/gen/models.g.dart' as api;
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';

/// The friendly played back fast (the web's QuickMatch): its minutes one by one with the score, then the best players.
class QuickMatchScreen extends StatefulWidget {
  const QuickMatchScreen({super.key, required this.home, required this.played});

  final String home;

  /// [Sprint 59 F1] The friendly as the generated model reads it (`Friendly`).
  final api.Friendly played;

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen> {
  late final List<api.FriendlyReportTimelineItem> _timeline = widget.played.report.timeline ?? const [];
  int _at = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (_at >= _timeline.length) return t.cancel();
      setState(() => _at++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final done = _at >= _timeline.length;
    final shown = _timeline.take(_at).where((e) => e.k != 'quiet' && e.k != 'attack').toList().reversed;
    final last = _at == 0 ? null : _timeline[_at - 1];
    final score = done ? [widget.played.goalsFor, widget.played.goalsAgainst] : (last?.score ?? const [0, 0]);
    final away = widget.played.opponent.name;
    final best = widget.played.report.best;
    String kind(String k) => switch (k) {
      'goal' => '⚽ ${l.kGoal}',
      'saved' => '🧤 ${l.kSaved}',
      'missed' => l.kMissed,
      'corner' => '⛳ ${l.kCorner}',
      'yellow' => '🟨 ${l.kYellow}',
      'red' => '🟥 ${l.kRed}',
      _ => l.kAttack,
    };
    return screenPage(
      l.friendlies,
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.home,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${score[0]} - ${score[1]}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 36, fontWeight: FontWeight.w800, color: p.text),
                    ),
                    Text(
                      done ? l.fullTime : "${last?.m ?? 0}'",
                      style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Expanded(
                  child: Text(
                    away,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          if (!done) TextButton(onPressed: () => setState(() => _at = _timeline.length), child: Text(l.skip)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (done && best.isNotEmpty)
                  GlmCard(
                    gold: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.bestOfMatch, style: context.text.titleMedium),
                        for (final b in best)
                          Row(
                            children: [
                              Expanded(
                                child: Text(b.name ?? '', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                              ),
                              Text(
                                (b.rating / 100).toStringAsFixed(1),
                                style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                for (final e in shown)
                  ListTile(
                    dense: true,
                    leading: Text(
                      "${e.m}'",
                      style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
                    ),
                    title: Text(kind(e.k), style: TextStyle(fontWeight: e.k == 'goal' ? FontWeight.w800 : FontWeight.w500)),
                    subtitle: e.name == null ? null : Text(e.name!, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                    trailing: Text(
                      e.s == 'home' ? widget.home : away,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: p.textMuted, fontSize: 12),
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
