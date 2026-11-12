part of 'tournament_screens.dart';

/// The alliance tournament of a league (X27): its two alliances and ties, my tie's «who goes on», or making one.
class AllianceScreen extends ConsumerStatefulWidget {
  const AllianceScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<AllianceScreen> createState() => _AllianceScreenState();
}

class _AllianceScreenState extends ConsumerState<AllianceScreen> {
  Future<void> _swap(Map<dynamic, dynamic> tie, int max) async {
    final l = L.of(context);
    final mine = tie['winner_id'];
    final other = (tie['home'] as Map<dynamic, dynamic>?)?['id'] == mine
        ? tie['away'] as Map<dynamic, dynamic>?
        : tie['home'] as Map<dynamic, dynamic>?;
    if (other == null) return;
    final api = ref.read(apiProvider);
    final lists = await Future.wait([
      api.get('/leagues/${widget.leagueId}/clubs/$mine'),
      api.get('/leagues/${widget.leagueId}/clubs/${other['id']}'),
    ]);
    if (!mounted) return;
    final give = <int>{}, take = <int>{};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SizedBox(
          height: MediaQuery.of(ctx).size.height * .75,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (title, list, chosen) in [(l.swapGive, lists[0], give), (l.swapTake, lists[1], take)])
                      Expanded(
                        child: ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            for (final pl in (list['players'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>())
                              CheckboxListTile(
                                dense: true,
                                value: chosen.contains(pl['id']),
                                title: Text(
                                  '${pl['name']}',
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.start,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('${pl['position']} ${pl['overall']}', textDirection: TextDirection.ltr),
                                onChanged: (on) => set(
                                  () => on == true ? (chosen.length < max ? chosen.add(pl['id'] as int) : null) : chosen.remove(pl['id']),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GlmButton(
                    label: l.send,
                    block: true,
                    onPressed: give.isEmpty || take.isEmpty ? null : () => Navigator.pop(ctx, true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true && mounted) {
      await _try(
        context,
        () => api.post('/leagues/${widget.leagueId}/alliance/ties/${tie['id']}/swap', {'give': give.toList(), 'take': take.toList()}),
      );
      ref.invalidate(allianceProvider(widget.leagueId));
    }
  }

  final _name = TextEditingController();
  String? _a, _b;
  double? _size;
  DateTime? _first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _page(
      l.alliance,
      AsyncView(
        value: ref.watch(allianceProvider(widget.leagueId)),
        onRetry: () => ref.invalidate(allianceProvider(widget.leagueId)),
        data: (d) {
          final p = context.palette;
          final t = d['tournament'] as Map<dynamic, dynamic>?;
          final coaches = (d['coaches'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>();
          final sizes = (d['sizes'] as List<dynamic>? ?? const [1, 5]).cast<int>();
          _size ??= (d['default_size'] as int? ?? 2).toDouble();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.allianceLead,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 12),
              if (t != null) ...[
                Text('${t['name']}', style: context.text.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                for (final x in (t['ties'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlmCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${(x['home'] as Map<dynamic, dynamic>?)?['name'] ?? '—'}',
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                x['score'] is Map<dynamic, dynamic>
                                    ? '${(x['score'] as Map<dynamic, dynamic>)['home']} - ${(x['score'] as Map<dynamic, dynamic>)['away']}'
                                    : 'vs',
                                textDirection: TextDirection.ltr,
                              ),
                              Expanded(
                                child: Text(
                                  '${(x['away'] as Map<dynamic, dynamic>?)?['name'] ?? '—'}',
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          // [Sprint 40 D2] The one who went on swaps players with the team he passed.
                          if (x['winner_id'] != null &&
                              x['winner_id'] == t['my_club_id'] &&
                              (x['swaps'] as int? ?? 0) < (t['swap_max'] as int? ?? 3))
                            GlmButton(
                              label: l.swapPlayers((t['swap_max'] as int? ?? 3) - (x['swaps'] as int? ?? 0)),
                              variant: GlmButtonVariant.quiet,
                              onPressed: () => _swap(x, (t['swap_max'] as int? ?? 3) - (x['swaps'] as int? ?? 0)),
                            ),
                          if (x['winner_id'] == null &&
                              t['my_club_id'] != null &&
                              [
                                (x['home'] as Map<dynamic, dynamic>?)?['id'],
                                (x['away'] as Map<dynamic, dynamic>?)?['id'],
                              ].contains(t['my_club_id']))
                            Row(
                              children: [
                                for (final side in ['home', 'away'])
                                  if (x[side] is Map<dynamic, dynamic>)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: GlmButton(
                                          label: '${l.goesOn}: ${(x[side] as Map<dynamic, dynamic>)['code']}',
                                          variant: GlmButtonVariant.outline,
                                          onPressed: () async {
                                            await _try(
                                              context,
                                              () => ref.read(apiProvider).post(
                                                '/leagues/${widget.leagueId}/alliance/ties/${x['id']}/decide',
                                                {'winner': (x[side] as Map<dynamic, dynamic>)['id']},
                                              ),
                                            );
                                            ref.invalidate(allianceProvider(widget.leagueId));
                                          },
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ] else if (d['can_create'] != true)
                Center(child: Text(l.noAlliance)),
              if (d['can_create'] == true)
                GlmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _name,
                        maxLength: 40,
                        decoration: InputDecoration(labelText: l.leagueName),
                      ),
                      for (final (label, value, set) in [(l.captainA, _a, (String? v) => _a = v), (l.captainB, _b, (String? v) => _b = v)])
                        DropdownButtonFormField<String>(
                          initialValue: value,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: label),
                          items: [
                            for (final c in coaches)
                              DropdownMenuItem(value: '${c['username']}', child: Text('${c['name']} (@${c['username']})')),
                          ],
                          onChanged: (v) => setState(() => set(v)),
                        ),
                      Text(l.allianceSize(_size!.round())),
                      Slider(
                        value: _size!,
                        min: sizes.first.toDouble(),
                        max: sizes.last.toDouble(),
                        divisions: (sizes.last - sizes.first).clamp(1, 20),
                        activeColor: p.gold,
                        onChanged: (v) => setState(() => _size = v),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.firstRound),
                        subtitle: Text(_first == null ? '—' : when(context, _first!)),
                        onTap: () async {
                          final at = await pickWhen(context, DateTime.now().add(const Duration(days: 1)));
                          if (at != null) setState(() => _first = at);
                        },
                      ),
                      GlmButton(
                        label: l.createAlliance,
                        onPressed: _a == null || _b == null || _first == null
                            ? null
                            : () async {
                                await _try(
                                  context,
                                  () => ref.read(apiProvider).post('/leagues/${widget.leagueId}/alliance', {
                                    'name': _name.text.trim(),
                                    'captain_a': _a,
                                    'captain_b': _b,
                                    'size': _size!.round(),
                                    'first_round_at': _first!.toUtc().toIso8601String(),
                                  }),
                                );
                                ref.invalidate(allianceProvider(widget.leagueId));
                              },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
