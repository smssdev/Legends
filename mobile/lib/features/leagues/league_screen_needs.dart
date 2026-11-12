part of 'league_screen.dart';

/// What needs the coach now (the server's agenda), each a line with its way in; or «all set».
class _Needs extends StatelessWidget {
  const _Needs({required this.s, required this.leagueId});

  final ClubSummary s;
  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final base = '/leagues/$leagueId';
    final rows = [
      if (s.missed > 0) (Icons.history_rounded, l.missedMatches(s.missed), '$base/missed', p.brandLight),
      for (final n in s.needs)
        switch (n.kind) {
          'window' => (Icons.sensors_rounded, l.needWindow, '/match/${n.matchId}', p.danger),
          'lineup' => (Icons.person_off_rounded, '${l.needLineup} (${n.count})', '$base/lineup', p.danger),
          'offers' => (Icons.mark_email_unread_rounded, '${l.needOffers} (${n.count})', '$base/market', p.warning),
          'requests' => (Icons.how_to_reg_rounded, '${l.needRequests} (${n.count})', '$base?tab=more', p.warning),
          'training_empty' => (Icons.fitness_center_rounded, '${l.needTrainingEmpty} (${n.count})', '$base/training', p.textSoft),
          'training_done' => (Icons.task_alt_rounded, l.needTrainingDone, '$base/training', p.success),
          _ => (Icons.info_rounded, n.kind, base, p.textSoft),
        },
    ];
    if (rows.isEmpty) {
      return GlmCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconTile(Icons.verified_rounded, color: p.success, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.allClear, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
    return GlmCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, (icon, text, path, color)) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: Colors.white.withValues(alpha: .06)),
            InkWell(
              onTap: () => context.push(path),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    IconTile(icon, color: color, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab(this.lg);

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

class _MatchesTab extends StatelessWidget {
  const _MatchesTab(this.lg);

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
          Expanded(child: TabBarView(children: [_FixturesTab(lg), _TableTab(lg)])),
        ],
      ),
    );
  }
}

class _MarketTab extends StatelessWidget {
  const _MarketTab(this.lg);

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
          title: l.secDeals,
          icon: Icons.swap_horiz_rounded,
          items: [
            MenuItem(Icons.storefront_rounded, l.market, () => go('market'), subtitle: l.subMarket),
            MenuItem(Icons.travel_explore_rounded, l.scout, () => go('scout'), subtitle: l.subScout, color: p.brandLight),
          ],
        ),
      ],
      end: [
        MenuSection(
          title: l.secMoney,
          icon: Icons.payments_rounded,
          items: [
            MenuItem(Icons.account_balance_wallet_rounded, l.finance, () => go('finance'), subtitle: l.subFinance, color: p.success),
            MenuItem(Icons.stadium_rounded, l.stadium, () => go('stadium'), subtitle: l.subStadium),
            MenuItem(Icons.confirmation_number_rounded, l.cheerTickets, () => go('tickets'), subtitle: l.subTickets, color: p.warning),
          ],
        ),
      ],
    );
  }
}

class _MoreTab extends ConsumerWidget {
  const _MoreTab(this.lg);

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
        _CoachesTab(lg),
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

class _TableTab extends ConsumerWidget {
  const _TableTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    TextStyle num([bool strong = false]) => TextStyle(
      fontFamily: GlmFonts.numbers,
      fontSize: 16,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      color: strong ? p.text : p.textSoft,
    );
    return RefreshIndicator(
      onRefresh: () => ref.refresh(standingsProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(standingsProvider(lg.id)),
        onRetry: () => ref.invalidate(standingsProvider(lg.id)),
        data: (rows) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final r in rows)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: r.id == lg.myClubId ? p.gold.withValues(alpha: .14) : p.surface,
                  borderRadius: BorderRadius.circular(GlmSize.radiusLg),
                  border: Border.all(color: r.id == lg.myClubId ? p.gold.withValues(alpha: .5) : p.surfaceRaised),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 26, child: Text('${r.position}', style: num(true))),
                    ClubCrest(url: r.crestUrl, name: r.code, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (r.coach != null)
                            Text(
                              r.coach!,
                              style: TextStyle(color: p.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text('${r.played}', style: num(), textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${r.gd > 0 ? '+' : ''}${r.gd}',
                        style: num(),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text('${r.points}', style: num(true), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FixturesTab extends ConsumerWidget {
  const _FixturesTab(this.lg);

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(fixturesProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(fixturesProvider(lg.id)),
        onRetry: () => ref.invalidate(fixturesProvider(lg.id)),
        data: (all) {
          final shown = all.where((f) => !f.isBye).toList();
          if (shown.isEmpty) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l.noMatches, textAlign: TextAlign.center),
                ),
              ],
            );
          }
          // Grouped by round (league) or stage (cup), in their order.
          final groups = <String, List<Fixture>>{};
          for (final f in shown) {
            groups.putIfAbsent(f.competition == 'cup' ? '${l.cup} · ${f.stage ?? ''}' : l.round(f.round ?? 0), () => []).add(f);
          }
          final firstOpen = groups.keys.toList().indexWhere((k) => groups[k]!.any((f) => !f.finished));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final (i, k) in groups.keys.indexed)
                ExpansionTile(
                  initiallyExpanded: i == firstOpen || (firstOpen == -1 && i == groups.length - 1),
                  title: Text(k, style: context.text.titleMedium),
                  subtitle: groups[k]!.first.at == null
                      ? null
                      : Text(when(context, groups[k]!.first.at!), style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
                  children: [for (final f in groups[k]!) FixtureTile(f, mine: lg.myClubId)],
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _settings(BuildContext context, WidgetRef ref, League lg) async {
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

Future<void> _owner(BuildContext context, WidgetRef ref, String path, [Map<String, Object>? body]) async {
  try {
    await ref.read(apiProvider).post(path, body);
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
  }
  ref.invalidate(leagueProvider);
}
