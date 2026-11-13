import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../models.dart';
import 'fixtures_tab.dart';
import 'table_tab.dart';

class MatchesTab extends StatelessWidget {
  const MatchesTab(this.lg, {super.key});

  final League lg;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                for (final (icon, label, path) in [
                  (Icons.sports_rounded, l.matchday, 'matchday'),
                  (Icons.how_to_vote_rounded, l.predictions, 'predictions'),
                  (Icons.bar_chart_rounded, l.stats, 'stats'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ActionChip(
                        avatar: Icon(icon, size: 18, color: context.palette.gold),
                        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onPressed: () => context.push('/leagues/${lg.id}/$path'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TabBar(
            labelColor: context.glm.goldText,
            indicatorColor: context.palette.gold,
            tabs: [
              Tab(text: l.tabFixtures),
              Tab(text: l.tabTable),
            ],
          ),
          Expanded(child: TabBarView(children: [FixturesTab(lg), TableTab(lg)])),
        ],
      ),
    );
  }
}
