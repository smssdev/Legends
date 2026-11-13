import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;
import 'tournaments_data.dart';

class NewTournamentScreen extends ConsumerStatefulWidget {
  const NewTournamentScreen({super.key});

  @override
  ConsumerState<NewTournamentScreen> createState() => _NewTournamentScreenState();
}

class _NewTournamentScreenState extends ConsumerState<NewTournamentScreen> {
  String? _template;
  String _entry = 'pick';
  // [Sprint 18 J] Teams of my choice: national teams from the catalog, or clubs found by name.
  final Map<int, String> _picked = {};
  String _format = 'groups';
  int _groups = 4;
  bool _clubs = false;
  String _q = '';
  List<api.TeamCard> _found = const [];
  DateTime? _starts;
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<Widget> _custom(BuildContext context, api.TournamentsCatalogAnswer c) {
    final l = L.of(context);
    final p = context.palette;
    final groupCounts = c.limits.groupCounts.isEmpty ? const [1, 2, 4, 8] : c.limits.groupCounts;
    final pool = _clubs ? _found : c.nations.where((n) => _q.isEmpty || n.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return [
      const SizedBox(height: 10),
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'league', label: Text(l.formatLeague)),
          ButtonSegment(value: 'groups', label: Text(l.formatGroups)),
          ButtonSegment(value: 'knockout', label: Text(l.formatKnockout)),
        ],
        selected: {_format},
        onSelectionChanged: (x) => setState(() => _format = x.first),
      ),
      if (_format == 'groups')
        Wrap(
          spacing: 6,
          children: [
            for (final g in groupCounts)
              ChoiceChip(label: Text(l.groupsCount(g)), selected: _groups == g, onSelected: (_) => setState(() => _groups = g)),
          ],
        ),
      const SizedBox(height: 8),
      SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: false, label: Text(l.nationsTab)),
          ButtonSegment(value: true, label: Text(l.clubsTab)),
        ],
        selected: {_clubs},
        onSelectionChanged: (x) => setState(() => _clubs = x.first),
      ),
      TextField(
        decoration: InputDecoration(labelText: l.searchClubs, prefixIcon: const Icon(Icons.search_rounded)),
        onChanged: (v) async {
          setState(() => _q = v.trim());
          if (_clubs && v.trim().length >= 2) {
            final r = await ref
                .read(apiProvider)
                .get('/tournaments/clubs', query: {'q': v.trim()})
                .catchError((_) => <String, dynamic>{'clubs': <Object>[]});
            if (mounted) setState(() => _found = api.TournamentsClubsAnswer.fromJson(r).clubs);
          }
        },
      ),
      Text(
        l.chosenTeams(_picked.length),
        style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w700),
      ),
      if (_picked.isNotEmpty)
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final e in _picked.entries)
              InputChip(
                label: Text(e.value, textDirection: TextDirection.ltr),
                onDeleted: () => setState(() => _picked.remove(e.key)),
              ),
          ],
        ),
      SizedBox(
        height: 260,
        child: ListView(
          children: [
            for (final t in pool.take(60))
              CheckboxListTile(
                dense: true,
                value: _picked.containsKey(t.id),
                activeColor: p.gold,
                title: Text(t.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                subtitle: Text(t.league, style: TextStyle(color: p.textMuted, fontSize: 11)),
                onChanged: (on) => setState(() => on == true ? _picked[t.id] = t.name : _picked.remove(t.id)),
              ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return screenPage(
      l.newTournament,
      AsyncView(
        value: ref.watch(catalogProvider),
        onRetry: () => ref.invalidate(catalogProvider),
        data: (c) {
          final p = context.palette;
          final templates = [
            for (final t in c.templates)
              if (t.key != 'custom' && t.teams.isNotEmpty) t,
          ];
          final chosen = templates.where((t) => t.key == _template).firstOrNull;
          final perTeam = c.limits.coinsPerTeam;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TextField(
                controller: _name,
                maxLength: 60,
                decoration: InputDecoration(labelText: l.leagueName),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in templates)
                    ChoiceChip(
                      label: Text('${templateName(l, t.key)} · ${t.teams.length}'),
                      selected: _template == t.key,
                      selectedColor: p.gold.withValues(alpha: .28),
                      onSelected: (_) => setState(() => _template = t.key),
                    ),
                  ChoiceChip(
                    label: Text(l.customTeams),
                    selected: _template == 'custom',
                    selectedColor: p.gold.withValues(alpha: .28),
                    onSelected: (_) => setState(() => _template = 'custom'),
                  ),
                ],
              ),
              if (_template == 'custom') ..._custom(context, c),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: _entry,
                onChanged: (v) => setState(() => _entry = v ?? 'pick'),
                child: Column(
                  children: [
                    RadioListTile(value: 'pick', title: Text(l.entryPick), activeColor: p.gold, contentPadding: EdgeInsets.zero),
                    RadioListTile(value: 'draw', title: Text(l.entryDraw), activeColor: p.gold, contentPadding: EdgeInsets.zero),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event_rounded, color: p.gold),
                title: Text(l.startsOn),
                subtitle: Text(_starts == null ? '—' : when(context, _starts!)),
                onTap: () async {
                  final d = await pickWhen(context, DateTime.now().add(const Duration(days: 1)));
                  if (d != null) setState(() => _starts = d);
                },
              ),
              if (chosen != null)
                Text(
                  l.tournamentCost(perTeam * chosen.teams.length),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.glm.goldText),
                ),
              if (_template == 'custom' && _picked.isNotEmpty)
                Text(
                  l.tournamentCost(perTeam * _picked.length),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.glm.goldText),
                ),
              const SizedBox(height: 12),
              GlmButton(
                label: l.create,
                block: true,
                loading: _busy,
                onPressed: (chosen == null && !(_template == 'custom' && _picked.length >= 2)) || _starts == null
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        final shape = chosen == null
                            ? {
                                'template': 'custom',
                                'teams': _picked.keys.toList(),
                                'format': _format,
                                if (_format == 'groups') ...{'group_count': _groups, 'advance_per_group': 2},
                                'legs': 1,
                              }
                            : {
                                'template': chosen.key,
                                'teams': chosen.teams,
                                'format': chosen.format,
                                'group_count': chosen.groupCount,
                                'advance_per_group': chosen.advancePerGroup,
                                'best_thirds': chosen.bestThirds,
                                'legs': chosen.legs,
                              };
                        final r = await tryAction(
                          context,
                          () => ref.read(apiProvider).post('/tournaments', {
                            if (_name.text.trim().isNotEmpty) 'name': _name.text.trim(),
                            ...shape,
                            'starts_at': _starts!.toUtc().toIso8601String(),
                            'entry_mode': _entry,
                            'timezone': 'Africa/Cairo',
                          }),
                        );
                        if (mounted) setState(() => _busy = false);
                        ref.invalidate(tournamentsProvider);
                        final id = r == null
                            ? null
                            : JsonReader(r, 'NewTournament').objectOrNull('tournament', (j) => JsonReader(j, 'Tournament').int_('id'));
                        if (id != null && context.mounted) context.pushReplacement('/tournaments/$id');
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
