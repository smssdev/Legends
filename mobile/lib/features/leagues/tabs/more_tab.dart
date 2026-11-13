import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/game.dart';
import '../../../ui/widgets/glm_background.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../account/profile_screen.dart' show askHoliday;
import '../../club/extras_data.dart';
import '../../home/home_data.dart';
import '../../money/finance_screen.dart' show confirm;
import '../../tournaments/tournaments_data.dart' show pickWhen;
import '../leagues_repository.dart';
import '../models.dart';
import '../widgets.dart';
import 'coaches_tab.dart';

class MoreTab extends ConsumerWidget {
  const MoreTab(this.lg, {super.key});

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    void go(String path) => context.push(path.startsWith('/') ? path : '/leagues/${lg.id}/$path');
    return GamePanes(
      startFlex: 1,
      endFlex: 1,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      start: [
        MenuSection(
          title: l.secCompete,
          icon: Icons.emoji_events_rounded,
          items: [
            MenuItem(Icons.sports_soccer_rounded, l.friendlies, () => go('friendlies'), subtitle: l.subFriendlies, color: p.success),
            MenuItem(Icons.flag_rounded, l.quests, () => go('quests'), subtitle: l.subQuests),
            MenuItem(Icons.visibility_rounded, l.spy, () => go('spy'), subtitle: l.subSpy, color: p.danger),
            MenuItem(Icons.handshake_rounded, l.alliance, () => go('alliance'), subtitle: l.subAlliance, color: p.brandLight),
            MenuItem(Icons.emoji_events_outlined, l.tournaments, () => go('/tournaments'), subtitle: l.subTournaments, color: p.warning),
            MenuItem(Icons.military_tech_rounded, l.honours, () => go('honours'), subtitle: l.subHonours),
          ],
        ),
        MenuSection(
          title: l.secCommunity,
          icon: Icons.forum_rounded,
          items: [
            MenuItem(Icons.newspaper_rounded, l.newspaper, () => go('newspaper'), subtitle: l.subNewspaper, color: p.textSoft),
            MenuItem(Icons.forum_rounded, l.groups, () => go('/groups'), subtitle: l.subGroups, color: p.brandLight),
          ],
        ),
      ],
      end: [
        GameHeader(l.secLeague, icon: Icons.groups_2_rounded),
        CoachesTab(lg),
        const SizedBox(height: 12),
        // [Sprint 18] A holiday in this league, asked of its creator.
        GlmButton(
          label: l.holidayLeague,
          variant: GlmButtonVariant.quiet,
          icon: const Icon(Icons.beach_access_rounded),
          onPressed: () => askHoliday(context, ref, '/leagues/${lg.id}/vacation', 14),
        ),
        // [Sprint 18] Leaving the league: the team goes back to the computer (Leaving::resign), after a clear yes.
        const SizedBox(height: 20),
        GlmButton(
          label: l.resign,
          variant: GlmButtonVariant.danger,
          onPressed: () async {
            if (!await confirm(context, l.resignConfirm) || !context.mounted) return;
            try {
              await ref.read(extrasRepositoryProvider).resign(lg.id);
              ref.invalidate(homeProvider);
              ref.invalidate(myLeaguesProvider);
              if (context.mounted) context.go('/');
            } on ApiError catch (e) {
              if (context.mounted) showGlmToast(context, e.message, error: true);
            }
          },
        ),
      ],
    );
  }
}

/// The league creator's settings sheet: its name, its rules and its days, saved on the server.
Future<void> editLeagueSettings(BuildContext context, WidgetRef ref, League lg) async {
  final l = L.of(context);
  final name = TextEditingController(text: lg.name);
  DateTime? starts = lg.startsAt?.toLocal();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.leagueSettings, style: ctx.text.titleMedium),
            TextField(
              controller: name,
              maxLength: 60,
              decoration: InputDecoration(labelText: l.leagueName),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.startsOn),
              subtitle: Text(starts == null ? '—' : when(ctx, starts!)),
              onTap: () async {
                final d = await pickWhen(ctx, DateTime.now().add(const Duration(hours: 2)));
                if (d != null) set(() => starts = d);
              },
            ),
            GlmButton(label: l.save, block: true, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    ),
  );
  if (ok == true && context.mounted) {
    try {
      await ref.read(apiProvider).patch('/leagues/${lg.id}', {
        'name': name.text.trim(),
        if (starts != null) 'starts_at': starts!.toUtc().toIso8601String(),
      });
      if (context.mounted) showGlmToast(context, l.saved);
    } on ApiError catch (e) {
      if (context.mounted) showGlmToast(context, e.message, error: true);
    }
    ref.invalidate(leagueProvider(lg.id));
  }
  name.dispose();
}

/// One of the league creator's actions on a member (a holiday approved or refused, a coach sent off): its refusal shown.
Future<void> ownerAction(BuildContext context, WidgetRef ref, String path, [Map<String, Object>? body]) async {
  try {
    await ref.read(apiProvider).post(path, body);
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
  }
  ref.invalidate(leagueProvider);
}
