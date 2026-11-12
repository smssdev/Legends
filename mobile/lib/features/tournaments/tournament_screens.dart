import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/widgets.dart' show when;
import '../leagues/shell.dart';

part 'tournament_screen.dart';
part 'tournament_screens_alliance_screen.dart';

/// [Sprint 18 G] Tournaments (Sprint 29) and the alliance tournament (X27) in the app: my tournaments, a new one from
/// a template, its page (code, entry, groups), and its draw replayed on the server's clock, one ball every reveal_ms
/// from drawn_at, so every screen shows the same ball at the same moment. Picking teams one by one stays on the site.
final tournamentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async => [
    for (final t in (await ref.read(apiProvider).get('/tournaments'))['tournaments'] as List<dynamic>? ?? const [])
      t as Map<String, dynamic>,
  ],
);
final catalogProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.read(apiProvider).get('/tournaments/catalog'));
final tournamentProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, id) async => (await ref.read(apiProvider).get('/tournaments/$id'))['tournament'] as Map<String, dynamic>,
);
final drawProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, id) => ref.read(apiProvider).get('/tournaments/$id/draw'),
);
final allianceProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, id) => ref.read(apiProvider).get('/leagues/$id/alliance'),
);

Future<T?> _try<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
    return null;
  }
}

Widget _page(String title, Widget body, {Widget? fab}) => Scaffold(
  appBar: GameBar(title: Text(title)),
  floatingActionButton: fab,
  body: GlmBackground(child: body),
);

String templateName(L l, String key) => switch (key) {
  'world_cup' => l.tplWorldCup,
  'world_cup_48' => l.tplWorldCup48,
  'club_world_cup' => l.tplClubWorldCup,
  'afcon' => l.tplAfcon,
  'euro' => l.tplEuro,
  'asian_cup' => l.tplAsianCup,
  _ => key,
};

/// A date and then a time, from the device's pickers; null when either is dismissed.
Future<DateTime?> pickWhen(BuildContext context, DateTime from) async {
  final day = await showDatePicker(context: context, firstDate: from, lastDate: from.add(const Duration(days: 60)), initialDate: from);
  if (day == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 21, minute: 0));
  if (time == null) return null;
  return DateTime(day.year, day.month, day.day, time.hour, time.minute);
}

class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.tournaments,
      AsyncView(
        value: ref.watch(tournamentsProvider),
        onRetry: () => ref.invalidate(tournamentsProvider),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noTournaments))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final t in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlmCard(
                        onTap: () => context.push('/tournaments/${(t as Map<dynamic, dynamic>)['id']}'),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events_rounded, color: context.palette.gold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${t['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(
                                    '${templateName(l, '${t['template']}')} · ${l.teamsCount(t['team_count'] as int? ?? 0)}',
                                    style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
      fab: FloatingActionButton.extended(
        onPressed: () => context.push('/tournaments/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.newTournament),
      ),
    );
  }
}

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
  List<Map<dynamic, dynamic>> _found = const [];
  DateTime? _starts;
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<Widget> _custom(BuildContext context, Map<String, dynamic> c) {
    final l = L.of(context);
    final p = context.palette;
    final groupCounts = ((c['limits'] as Map<dynamic, dynamic>?)?['group_counts'] as List<dynamic>? ?? const [1, 2, 4, 8]).cast<int>();
    final pool = _clubs
        ? _found
        : (c['nations'] as List<dynamic>? ?? const [])
              .cast<Map<dynamic, dynamic>>()
              .where((n) => _q.isEmpty || '${n['name']}'.toLowerCase().contains(_q.toLowerCase()))
              .toList();
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
            final r = await ref.read(apiProvider).get('/tournaments/clubs', query: {'q': v.trim()}).catchError((_) => <String, dynamic>{});
            if (mounted) setState(() => _found = (r['clubs'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>());
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
                value: _picked.containsKey(t['id']),
                activeColor: p.gold,
                title: Text('${t['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                subtitle: Text('${t['league'] ?? ''}', style: TextStyle(color: p.textMuted, fontSize: 11)),
                onChanged: (on) => setState(() => on == true ? _picked[t['id'] as int] = '${t['name']}' : _picked.remove(t['id'])),
              ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _page(
      l.newTournament,
      AsyncView(
        value: ref.watch(catalogProvider),
        onRetry: () => ref.invalidate(catalogProvider),
        data: (c) {
          final p = context.palette;
          final templates = [
            for (final t in (c['templates'] as List<dynamic>? ?? const []))
              if ((t as Map<dynamic, dynamic>)['key'] != 'custom' && (t['teams'] as List<dynamic>).isNotEmpty) t,
          ];
          final chosen = templates.where((t) => t['key'] == _template).firstOrNull;
          final perTeam = (c['limits'] as Map<dynamic, dynamic>?)?['coins_per_team'] as int? ?? 0;
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
                      label: Text('${templateName(l, '${t['key']}')} · ${(t['teams'] as List<dynamic>).length}'),
                      selected: _template == t['key'],
                      selectedColor: p.gold.withValues(alpha: .28),
                      onSelected: (_) => setState(() => _template = '${t['key']}'),
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
                  l.tournamentCost(perTeam * (chosen['teams'] as List<dynamic>).length),
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
                                'template': chosen['key'],
                                'teams': chosen['teams'],
                                'format': chosen['format'],
                                'group_count': chosen['group_count'],
                                'advance_per_group': chosen['advance_per_group'],
                                'best_thirds': chosen['best_thirds'],
                                'legs': chosen['legs'],
                              };
                        final r = await _try(
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
                        final id = ((r?['tournament'] as Map<dynamic, dynamic>?)?['id']) as int?;
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
