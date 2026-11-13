import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import 'team_data.dart';

/// [Sprint 60 F4] The captain and the set-piece takers, as the site's TakersPage (Sprint 48 T4), which the app did not
/// have: a card each with the player, his rating and his skill at it, and «تبديل اللاعب» to choose from the whole squad
/// ranked by that skill (the server's), or leave it to the server (the best of the eleven).
class TakersScreen extends ConsumerWidget {
  const TakersScreen({super.key, required this.leagueId});

  final int leagueId;

  static const roles = ['captain', 'penalty', 'free_kick', 'corner'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
      l.takersTitle,
      AsyncView(
        value: ref.watch(teamProvider(leagueId)),
        onRetry: () => ref.invalidate(teamProvider(leagueId)),
        data: (team) => LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 700 ? 2 : 1;
            final w = (box.maxWidth - 24 - (cols - 1) * GlmSpace.sm) / cols;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: GlmSpace.sm,
                runSpacing: GlmSpace.sm,
                children: [
                  for (final role in roles)
                    SizedBox(
                      width: w,
                      child: _RoleCard(role: role, team: team, pick: (id) => _set(context, ref, team, role, id)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// The four roles go together (the server takes them at once): this one changed, the others as the coach chose them.
  Future<void> _set(BuildContext context, WidgetRef ref, TeamData team, String role, int? id) async {
    final body = {for (final r in roles) r: r == role ? id : team.takers[r]?.chosenId};
    final saved = await tryAction(context, () => ref.read(teamRepositoryProvider).saveTakers(leagueId, body));
    if (saved != null) ref.invalidate(teamProvider(leagueId));
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.team, required this.pick});

  final String role;
  final TeamData team;
  final ValueChanged<int?> pick;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final t = team.takers[role];
    final holder = t?.playerId == null ? null : team.byId(t!.playerId!);
    final skill = t?.candidates.where((c) => c.id == holder?.id).firstOrNull?.skill;
    final (title, skillName, icon) = switch (role) {
      'captain' => (l.roleCaptain, l.skillCaptain, Icons.shield_rounded),
      'penalty' => (l.rolePenalty, l.skillPenalty, Icons.sports_soccer_rounded),
      'free_kick' => (l.roleFreeKick, l.skillFreeKick, Icons.flag_rounded),
      _ => (l.roleCorner, l.skillCorner, Icons.turn_slight_left_rounded),
    };
    return GlmCard(
      padding: const EdgeInsets.all(GlmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: p.gold),
              const SizedBox(width: GlmSpace.sm),
              Expanded(child: Text(title, style: context.type.title)),
              if (t?.auto ?? true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: GlmSpace.sm, vertical: 2),
                  decoration: BoxDecoration(color: p.surfaceRaised, borderRadius: BorderRadius.circular(GlmRadius.pill)),
                  child: Text(l.takerAutoBadge, style: context.type.caption),
                ),
            ],
          ),
          const SizedBox(height: GlmSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  holder?.name ?? '—',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: context.type.bodyLg.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (holder != null) ...[
                _Number('${holder.overall}', l.ratingWord),
                const SizedBox(width: GlmSpace.md),
                if (skill != null) _Number('$skill', skillName),
              ],
            ],
          ),
          const SizedBox(height: GlmSpace.md),
          GlmButton(
            label: l.changePlayer,
            variant: GlmButtonVariant.quiet,
            block: true,
            onPressed: () async {
              final chosen = await showModalBottomSheet<({int? id})>(
                context: context,
                showDragHandle: true,
                backgroundColor: p.panel,
                builder: (_) => _Candidates(team: team, taker: t, skillName: skillName),
              );
              if (chosen != null) pick(chosen.id);
            },
          ),
        ],
      ),
    );
  }
}

class _Number extends StatelessWidget {
  const _Number(this.value, this.label);

  final String value, label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: context.type.numbers(context.type.title).copyWith(color: context.glm.goldText)),
      Text(label, style: context.type.caption),
    ],
  );
}

/// The squad ranked by the role's skill (the server's order), the eleven marked; «تلقائي» first.
class _Candidates extends StatelessWidget {
  const _Candidates({required this.team, required this.taker, required this.skillName});

  final TeamData team;
  final Taker? taker;
  final String skillName;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ListTile(
            leading: Icon(Icons.auto_awesome_rounded, color: p.gold),
            title: Text(l.takerAuto),
            selected: taker?.chosenId == null,
            onTap: () => Navigator.pop(context, (id: null)),
          ),
          for (final c in taker?.candidates ?? const <({int id, int skill, bool on})>[])
            if (team.byId(c.id) case final pl?)
              ListTile(
                title: Text(pl.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                subtitle: Text('${pl.position} · ${c.on ? l.inEleven : l.outOfEleven}', style: context.type.caption),
                trailing: Text(
                  '$skillName ${c.skill}',
                  style: context.type.numbers(context.type.body).copyWith(color: context.glm.goldText),
                ),
                selected: taker?.chosenId == c.id,
                onTap: () => Navigator.pop(context, (id: c.id)),
              ),
        ],
      ),
    );
  }
}
