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

/// [Sprint 18 G] Tournaments (Sprint 29) and the alliance tournament (X27) in the app: my tournaments, a new one from
/// a template, its page (code, entry, groups), and its draw replayed on the server's clock, one ball every reveal_ms
/// from drawn_at, so every screen shows the same ball at the same moment. Picking teams one by one stays on the site.
final tournamentsProvider = FutureProvider.autoDispose<List>((ref) async => (await ref.read(apiProvider).get('/tournaments'))['tournaments'] as List? ?? const []);
final catalogProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.read(apiProvider).get('/tournaments/catalog'));
final tournamentProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
    (ref, id) async => (await ref.read(apiProvider).get('/tournaments/$id'))['tournament'] as Map<String, dynamic>);
final drawProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) => ref.read(apiProvider).get('/tournaments/$id/draw'));
final allianceProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) => ref.read(apiProvider).get('/leagues/$id/alliance'));

Future<T?> _try<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
    return null;
  }
}

Widget _page(String title, Widget body, {Widget? fab}) =>
    Scaffold(appBar: GameBar(title: Text(title)), floatingActionButton: fab, body: GlmBackground(child: body));

String templateName(L l, String key) => switch (key) {
      'world_cup' => l.tplWorldCup, 'world_cup_48' => l.tplWorldCup48, 'club_world_cup' => l.tplClubWorldCup,
      'afcon' => l.tplAfcon, 'euro' => l.tplEuro, 'asian_cup' => l.tplAsianCup, _ => key,
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
            : ListView(padding: const EdgeInsets.all(12), children: [
                for (final t in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlmCard(
                      onTap: () => context.push('/tournaments/${(t as Map)['id']}'),
                      child: Row(children: [
                        Icon(Icons.emoji_events_rounded, color: context.palette.gold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${t['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text('${templateName(l, '${t['template']}')} · ${l.teamsCount(t['team_count'] as int? ?? 0)}', style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ]),
                    ),
                  ),
              ]),
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
  List<Map> _found = const [];
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
    final groupCounts = ((c['limits'] as Map?)?['group_counts'] as List? ?? const [1, 2, 4, 8]).cast<int>();
    final pool = _clubs ? _found : (c['nations'] as List? ?? const []).cast<Map>().where((n) => _q.isEmpty || '${n['name']}'.toLowerCase().contains(_q.toLowerCase())).toList();
    return [
      const SizedBox(height: 10),
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [ButtonSegment(value: 'league', label: Text(l.formatLeague)), ButtonSegment(value: 'groups', label: Text(l.formatGroups)), ButtonSegment(value: 'knockout', label: Text(l.formatKnockout))],
        selected: {_format},
        onSelectionChanged: (x) => setState(() => _format = x.first),
      ),
      if (_format == 'groups')
        Wrap(spacing: 6, children: [
          for (final g in groupCounts) ChoiceChip(label: Text(l.groupsCount(g)), selected: _groups == g, onSelected: (_) => setState(() => _groups = g)),
        ]),
      const SizedBox(height: 8),
      SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [ButtonSegment(value: false, label: Text(l.nationsTab)), ButtonSegment(value: true, label: Text(l.clubsTab))],
        selected: {_clubs},
        onSelectionChanged: (x) => setState(() => _clubs = x.first),
      ),
      TextField(
        decoration: InputDecoration(labelText: l.searchClubs, prefixIcon: const Icon(Icons.search_rounded)),
        onChanged: (v) async {
          setState(() => _q = v.trim());
          if (_clubs && v.trim().length >= 2) {
            final r = await ref.read(apiProvider).get('/tournaments/clubs', query: {'q': v.trim()}).catchError((_) => <String, dynamic>{});
            if (mounted) setState(() => _found = (r['clubs'] as List? ?? const []).cast<Map>());
          }
        },
      ),
      Text(l.chosenTeams(_picked.length), style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w700)),
      if (_picked.isNotEmpty)
        Wrap(spacing: 4, runSpacing: 4, children: [
          for (final e in _picked.entries) InputChip(label: Text(e.value, textDirection: TextDirection.ltr), onDeleted: () => setState(() => _picked.remove(e.key))),
        ]),
      SizedBox(
        height: 260,
        child: ListView(children: [
          for (final t in pool.take(60))
            CheckboxListTile(
              dense: true,
              value: _picked.containsKey(t['id']),
              activeColor: p.gold,
              title: Text('${t['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
              subtitle: Text('${t['league'] ?? ''}', style: TextStyle(color: p.textMuted, fontSize: 11)),
              onChanged: (on) => setState(() => on == true ? _picked[t['id'] as int] = '${t['name']}' : _picked.remove(t['id'])),
            ),
        ]),
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
          final templates = [for (final t in (c['templates'] as List? ?? const [])) if ((t as Map)['key'] != 'custom' && (t['teams'] as List).isNotEmpty) t];
          final chosen = templates.where((t) => t['key'] == _template).firstOrNull;
          final perTeam = (c['limits'] as Map?)?['coins_per_team'] as int? ?? 0;
          return ListView(padding: const EdgeInsets.all(12), children: [
            TextField(controller: _name, maxLength: 60, decoration: InputDecoration(labelText: l.leagueName)),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in templates)
                ChoiceChip(
                  label: Text('${templateName(l, '${t['key']}')} · ${(t['teams'] as List).length}'),
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
            ]),
            if (_template == 'custom') ..._custom(context, c),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _entry,
              onChanged: (v) => setState(() => _entry = v ?? 'pick'),
              child: Column(children: [
                RadioListTile(value: 'pick', title: Text(l.entryPick), activeColor: p.gold, contentPadding: EdgeInsets.zero),
                RadioListTile(value: 'draw', title: Text(l.entryDraw), activeColor: p.gold, contentPadding: EdgeInsets.zero),
              ]),
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
            if (chosen != null) Text(l.tournamentCost(perTeam * (chosen['teams'] as List).length), textAlign: TextAlign.center, style: TextStyle(color: context.glm.goldText)),
            if (_template == 'custom' && _picked.isNotEmpty) Text(l.tournamentCost(perTeam * _picked.length), textAlign: TextAlign.center, style: TextStyle(color: context.glm.goldText)),
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
                          ? {'template': 'custom', 'teams': _picked.keys.toList(), 'format': _format, if (_format == 'groups') ...{'group_count': _groups, 'advance_per_group': 2}, 'legs': 1}
                          : {'template': chosen['key'], 'teams': chosen['teams'], 'format': chosen['format'], 'group_count': chosen['group_count'],
                              'advance_per_group': chosen['advance_per_group'], 'best_thirds': chosen['best_thirds'], 'legs': chosen['legs']};
                      final r = await _try(context, () => ref.read(apiProvider).post('/tournaments', {
                            if (_name.text.trim().isNotEmpty) 'name': _name.text.trim(),
                            ...shape,
                            'starts_at': _starts!.toUtc().toIso8601String(), 'entry_mode': _entry, 'timezone': 'Africa/Cairo',
                          }));
                      if (mounted) setState(() => _busy = false);
                      ref.invalidate(tournamentsProvider);
                      final id = ((r?['tournament'] as Map?)?['id']) as int?;
                      if (id != null && context.mounted) context.pushReplacement('/tournaments/$id');
                    },
            ),
          ]);
        },
      ),
    );
  }
}

class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.tournaments,
      AsyncView(
        value: ref.watch(tournamentProvider(id)),
        onRetry: () => ref.invalidate(tournamentProvider(id)),
        data: (t) {
          final p = context.palette;
          final entry = t['entry'] as Map? ?? const {};
          final teams = (t['teams'] as List? ?? const []).cast<Map>();
          final groups = <String, List<Map>>{};
          for (final x in teams) {
            if (x['group'] != null) (groups['${x['group']}'] ??= []).add(x);
          }
          final code = '${t['code'] ?? ''}';
          Future<void> act(Future<Object?> Function() a) async {
            await _try(context, a);
            ref.invalidate(tournamentProvider(id));
          }

          return ListView(padding: const EdgeInsets.all(12), children: [
            GlmCard(
              gold: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${t['name']}', style: context.text.titleLarge),
                Text('${templateName(l, '${t['template']}')} · ${l.teamsCount(t['team_count'] as int? ?? 0)}', style: TextStyle(color: p.textMuted)),
                if (DateTime.tryParse('${t['starts_at']}') != null) Text('${l.startsOn}: ${when(context, DateTime.parse('${t['starts_at']}').toLocal())}'),
                const SizedBox(height: 10),
                Text(l.tournamentCode, style: TextStyle(color: p.textMuted, fontSize: 12)),
                SelectableText(code, textAlign: TextAlign.center, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 28, letterSpacing: 4, fontWeight: FontWeight.w800, color: context.glm.goldText)),
                Row(children: [
                  Expanded(child: GlmButton(label: l.share, icon: const Icon(Icons.share_rounded), onPressed: () => SharePlus.instance.share(ShareParams(text: '${AppConfig.siteUrl}/join/$code')))),
                  const SizedBox(width: 8),
                  Expanded(child: GlmButton(label: l.code, variant: GlmButtonVariant.quiet, icon: const Icon(Icons.copy_rounded), onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    showGlmToast(context, l.copied);
                  })),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            if (entry['mode'] == 'draw' && (entry['can_enter'] == true || entry['is_entrant'] == true))
              GlmButton(
                label: entry['is_entrant'] == true ? l.leaveEntry : l.enter,
                variant: entry['is_entrant'] == true ? GlmButtonVariant.outline : GlmButtonVariant.primary,
                block: true,
                onPressed: () => act(() => entry['is_entrant'] == true ? ref.read(apiProvider).delete('/tournaments/$id/entry') : ref.read(apiProvider).post('/tournaments/$id/entry')),
              ),
            const SizedBox(height: 8),
            GlmButton(label: l.watchDraw, variant: GlmButtonVariant.brand, icon: const Icon(Icons.casino_rounded), block: true, onPressed: () => context.push('/tournaments/$id/draw')),
            if (entry['is_member'] == true && t['status'] != 'waiting') ...[
              const SizedBox(height: 8),
              GlmButton(label: l.openLeague, variant: GlmButtonVariant.outline, block: true, onPressed: () => context.push('/leagues/$id')),
            ],
            const SizedBox(height: 12),
            for (final g in (groups.keys.toList()..sort()))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlmCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l.groupN(g), style: context.text.titleMedium),
                    for (final x in groups[g]!)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          ClubCrest(url: x['crest_url'] as String?, name: '${x['code']}', size: 24),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${x['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start)),
                          if (x['coach'] != null) Text('${(x['coach'] as Map?)?['name'] ?? x['coach']}', style: TextStyle(color: p.textMuted, fontSize: 12)),
                        ]),
                      ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

/// The draw: before it, its time (the organizer sets it); after, the balls one by one on the shared clock.
class DrawScreen extends ConsumerStatefulWidget {
  const DrawScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends ConsumerState<DrawScreen> {
  Timer? _tick;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _page(
      l.watchDraw,
      AsyncView(
        value: ref.watch(drawProvider(widget.id)),
        onRetry: () => ref.invalidate(drawProvider(widget.id)),
        data: (d) {
          final p = context.palette;
          _offset = ((d['server_now'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch) - DateTime.now().millisecondsSinceEpoch;
          final steps = (d['steps'] as List? ?? const []).cast<Map>();
          final drawnAt = DateTime.tryParse('${d['drawn_at'] ?? ''}');
          final drawAt = DateTime.tryParse('${d['draw_at'] ?? ''}');
          final revealMs = d['reveal_ms'] as int? ?? 3500;
          final now = DateTime.now().millisecondsSinceEpoch + _offset;
          final shown = drawnAt == null ? 0 : ((now - drawnAt.millisecondsSinceEpoch) ~/ revealMs + 1).clamp(0, steps.length);
          if (drawnAt == null && drawAt != null && now >= drawAt.millisecondsSinceEpoch) {
            // Its time has come: ask again for the balls.
            Future.microtask(() => ref.invalidate(drawProvider(widget.id)));
          }
          final groups = <int, List<Map>>{};
          for (final s in steps.take(shown)) {
            if (s['group'] != null) (groups[s['group'] as int] ??= []).add(s);
          }
          final last = shown == 0 ? null : steps[shown - 1];
          return ListView(padding: const EdgeInsets.all(12), children: [
            if (drawnAt == null) ...[
              Text(drawAt == null ? l.drawNotSet : l.drawAt(when(context, drawAt.toLocal())), textAlign: TextAlign.center, style: context.text.titleMedium),
              if (d['can_schedule'] == true) ...[
                const SizedBox(height: 10),
                GlmButton(
                  label: l.scheduleDraw,
                  icon: const Icon(Icons.schedule_rounded),
                  onPressed: () async {
                    final at = await pickWhen(context, DateTime.now());
                    if (at == null || !context.mounted) return;
                    await _try(context, () => ref.read(apiProvider).put('/leagues/${widget.id}/draw', {'draw_at': at.toUtc().toIso8601String()}));
                    ref.invalidate(drawProvider(widget.id));
                  },
                ),
              ],
            ] else ...[
              Text(l.drawnBalls(shown, steps.length), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
              if (last != null)
                GlmCard(
                  gold: true,
                  child: Column(children: [
                    ClubCrest(url: (last['club'] as Map?)?['crest_url'] as String?, name: '${(last['club'] as Map?)?['code'] ?? ''}', size: 64),
                    const SizedBox(height: 6),
                    Text('${(last['club'] as Map?)?['name'] ?? ''}', textDirection: TextDirection.ltr, style: context.text.titleLarge),
                    if (last['group'] != null) Text(l.groupN(String.fromCharCode(64 + (last['group'] as int))), style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800)),
                  ]),
                ),
              const SizedBox(height: 10),
              for (final g in (groups.keys.toList()..sort()))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(l.groupN(String.fromCharCode(64 + g)), style: const TextStyle(fontWeight: FontWeight.w800)),
                      for (final s in groups[g]!) Text('${(s['club'] as Map?)?['name'] ?? ''}', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                    ]),
                  ),
                ),
            ],
          ]);
        },
      ),
    );
  }
}

/// The alliance tournament of a league (X27): its two alliances and ties, my tie's «who goes on», or making one.
class AllianceScreen extends ConsumerStatefulWidget {
  const AllianceScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<AllianceScreen> createState() => _AllianceScreenState();
}

class _AllianceScreenState extends ConsumerState<AllianceScreen> {
  Future<void> _swap(Map tie, int max) async {
    final l = L.of(context);
    final mine = tie['winner_id'];
    final other = (tie['home'] as Map?)?['id'] == mine ? tie['away'] as Map? : tie['home'] as Map?;
    if (other == null) return;
    final api = ref.read(apiProvider);
    final lists = await Future.wait([api.get('/leagues/${widget.leagueId}/clubs/$mine'), api.get('/leagues/${widget.leagueId}/clubs/${other['id']}')]);
    if (!mounted) return;
    final give = <int>{}, take = <int>{};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SizedBox(
          height: MediaQuery.of(ctx).size.height * .75,
          child: Column(children: [
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final (title, list, chosen) in [(l.swapGive, lists[0], give), (l.swapTake, lists[1], take)])
                  Expanded(
                    child: ListView(children: [
                      Padding(padding: const EdgeInsets.all(8), child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
                      for (final pl in (list['players'] as List? ?? const []).cast<Map>())
                        CheckboxListTile(
                          dense: true,
                          value: chosen.contains(pl['id']),
                          title: Text('${pl['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${pl['position']} ${pl['overall']}', textDirection: TextDirection.ltr),
                          onChanged: (on) => set(() => on == true ? (chosen.length < max ? chosen.add(pl['id'] as int) : null) : chosen.remove(pl['id'])),
                        ),
                    ]),
                  ),
              ]),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GlmButton(label: l.send, block: true, onPressed: give.isEmpty || take.isEmpty ? null : () => Navigator.pop(ctx, true)),
              ),
            ),
          ]),
        ),
      ),
    );
    if (ok == true && mounted) {
      await _try(context, () => api.post('/leagues/${widget.leagueId}/alliance/ties/${tie['id']}/swap', {'give': give.toList(), 'take': take.toList()}));
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
          final t = d['tournament'] as Map?;
          final coaches = (d['coaches'] as List? ?? const []).cast<Map>();
          final sizes = (d['sizes'] as List? ?? const [1, 5]).cast<int>();
          _size ??= (d['default_size'] as int? ?? 2).toDouble();
          return ListView(padding: const EdgeInsets.all(12), children: [
            Text(l.allianceLead, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            const SizedBox(height: 12),
            if (t != null) ...[
              Text('${t['name']}', style: context.text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              for (final x in (t['ties'] as List? ?? const []).cast<Map>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Expanded(child: Text('${(x['home'] as Map?)?['name'] ?? '—'}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700))),
                        Text(x['score'] is Map ? '${(x['score'] as Map)['home']} - ${(x['score'] as Map)['away']}' : 'vs', textDirection: TextDirection.ltr),
                        Expanded(child: Text('${(x['away'] as Map?)?['name'] ?? '—'}', textDirection: TextDirection.ltr, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
                      ]),
                      // [Sprint 40 D2] The one who went on swaps players with the team he passed.
                      if (x['winner_id'] != null && x['winner_id'] == t['my_club_id'] && (x['swaps'] as int? ?? 0) < (t['swap_max'] as int? ?? 3))
                        GlmButton(
                          label: l.swapPlayers((t['swap_max'] as int? ?? 3) - (x['swaps'] as int? ?? 0)),
                          variant: GlmButtonVariant.quiet,
                          onPressed: () => _swap(x, (t['swap_max'] as int? ?? 3) - (x['swaps'] as int? ?? 0)),
                        ),
                      if (x['winner_id'] == null && t['my_club_id'] != null && [(x['home'] as Map?)?['id'], (x['away'] as Map?)?['id']].contains(t['my_club_id']))
                        Row(children: [
                          for (final side in ['home', 'away'])
                            if (x[side] is Map)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: GlmButton(
                                    label: '${l.goesOn}: ${(x[side] as Map)['code']}',
                                    variant: GlmButtonVariant.outline,
                                    onPressed: () async {
                                      await _try(context, () => ref.read(apiProvider).post('/leagues/${widget.leagueId}/alliance/ties/${x['id']}/decide', {'winner': (x[side] as Map)['id']}));
                                      ref.invalidate(allianceProvider(widget.leagueId));
                                    },
                                  ),
                                ),
                              ),
                        ]),
                    ]),
                  ),
                ),
            ] else if (d['can_create'] != true)
              Center(child: Text(l.noAlliance)),
            if (d['can_create'] == true)
              GlmCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextField(controller: _name, maxLength: 40, decoration: InputDecoration(labelText: l.leagueName)),
                  for (final (label, value, set) in [(l.captainA, _a, (String? v) => _a = v), (l.captainB, _b, (String? v) => _b = v)])
                    DropdownButtonFormField<String>(
                      initialValue: value,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: label),
                      items: [for (final c in coaches) DropdownMenuItem(value: '${c['username']}', child: Text('${c['name']} (@${c['username']})'))],
                      onChanged: (v) => setState(() => set(v)),
                    ),
                  Text(l.allianceSize(_size!.round())),
                  Slider(value: _size!, min: sizes.first.toDouble(), max: sizes.last.toDouble(), divisions: (sizes.last - sizes.first).clamp(1, 20), activeColor: p.gold,
                      onChanged: (v) => setState(() => _size = v)),
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
                            await _try(context, () => ref.read(apiProvider).post('/leagues/${widget.leagueId}/alliance', {
                                  'name': _name.text.trim(), 'captain_a': _a, 'captain_b': _b, 'size': _size!.round(), 'first_round_at': _first!.toUtc().toIso8601String(),
                                }));
                            ref.invalidate(allianceProvider(widget.leagueId));
                          },
                  ),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
