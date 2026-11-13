import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/game.dart';
import '../models.dart';

class TeamTab extends StatelessWidget {
  const TeamTab(this.lg, {super.key});

  final League lg;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    void go(String path) => context.push('/leagues/${lg.id}/$path');
    return GamePanes(
      startFlex: 1,
      endFlex: 1,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      start: [
        MenuSection(
          title: l.secPlayers,
          icon: Icons.groups_rounded,
          items: [
            MenuItem(Icons.groups_rounded, l.squad, () => go('squad'), subtitle: l.subSquad),
            MenuItem(Icons.grid_view_rounded, l.lineup, () => go('lineup'), subtitle: l.subLineup, color: p.success),
            MenuItem(Icons.tune_rounded, l.tactics, () => go('tactics'), subtitle: l.subTactics, color: p.brandLight),
          ],
        ),
      ],
      end: [
        MenuSection(
          title: l.secDevelop,
          icon: Icons.trending_up_rounded,
          items: [
            MenuItem(Icons.fitness_center_rounded, l.training, () => go('training'), subtitle: l.subTraining),
            MenuItem(Icons.workspace_premium_rounded, l.specialists, () => go('specialists'), subtitle: l.subSpecialists, color: p.warning),
            MenuItem(Icons.description_rounded, l.contracts, () => go('contracts'), subtitle: l.subContracts, color: p.textSoft),
          ],
        ),
      ],
    );
  }
}
