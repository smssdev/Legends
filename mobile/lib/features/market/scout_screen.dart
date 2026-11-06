import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/widgets.dart' show when;
import '../money/finance_screen.dart' show confirm;
import 'market_data.dart';
import 'market_screen.dart' show BuySheet;
import '../leagues/shell.dart';

/// [Sprint 18 F1] The scout (Sprint 26): the coach's terms, the price and the time from the server, the search under
/// way (finished now for coins at the server's price) and the reports, whose players he buys at the pool price.
class ScoutRequest {
  const ScoutRequest({required this.id, required this.status, required this.finishesAt, required this.players});

  factory ScoutRequest.fromJson(Map<String, dynamic> j) => ScoutRequest(
        id: j['id'] as int, status: '${j['status']}', finishesAt: DateTime.tryParse('${j['finishes_at'] ?? ''}'),
        players: [
          for (final p in (j['players'] as List? ?? const []))
            (player: MarketPlayer.fromJson(p as Map<String, dynamic>), state: '${p['state']}'),
        ],
      );

  final int id;
  final String status;
  final DateTime? finishesAt;
  final List<({MarketPlayer player, String state})> players;

  bool get searching => status == 'searching';
}

class ScoutView {
  const ScoutView({required this.cost, required this.hours, required this.finishCoins, required this.nationalities, required this.leagues, required this.requests});

  factory ScoutView.fromJson(Map<String, dynamic> j) {
    final o = j['options'] as Map<String, dynamic>? ?? const {};
    return ScoutView(
      cost: (j['cost'] as num?)?.toInt() ?? 0, hours: j['hours'] as int? ?? 0, finishCoins: j['finish_coins'] as int? ?? 0,
      nationalities: [for (final n in (o['nationalities'] as List? ?? const [])) '$n'],
      leagues: [for (final n in (o['leagues'] as List? ?? const [])) '$n'],
      requests: [for (final r in (j['requests'] as List? ?? const [])) ScoutRequest.fromJson(r as Map<String, dynamic>)],
    );
  }

  final int cost, hours, finishCoins;
  final List<String> nationalities, leagues;
  final List<ScoutRequest> requests;
}

class ScoutRepository {
  ScoutRepository(this._api);

  final ApiClient _api;

  Future<ScoutView> show(int league) async => ScoutView.fromJson(await _api.get('/leagues/$league/scout'));
  Future<ScoutView> ask(int league, Map<String, Object> criteria) async =>
      ScoutView.fromJson(await _api.post('/leagues/$league/scout', {...criteria, 'idempotency_key': 'app-${DateTime.now().microsecondsSinceEpoch}'}));
  Future<ScoutView> finishNow(int league) async => ScoutView.fromJson(await _api.post('/leagues/$league/scout/finish'));
}

final scoutRepositoryProvider = Provider<ScoutRepository>((ref) => ScoutRepository(ref.watch(apiProvider)));
final scoutProvider = FutureProvider.autoDispose.family<ScoutView, int>((ref, league) => ref.read(scoutRepositoryProvider).show(league));

class ScoutScreen extends ConsumerStatefulWidget {
  const ScoutScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<ScoutScreen> createState() => _ScoutScreenState();
}

class _ScoutScreenState extends ConsumerState<ScoutScreen> {
  String? _line, _nation, _league;
  double _min = 70, _age = 30;
  bool _busy = false;
  ScoutView? _fresh;

  Future<void> _run(Future<ScoutView> Function() action) async {
    setState(() => _busy = true);
    try {
      final v = await action();
      if (mounted) setState(() => _fresh = v);
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final repo = ref.read(scoutRepositoryProvider);
    return Scaffold(
      appBar: GameBar(title: Text(l.scout)),
      body: GlmBackground(
        child: AsyncView(
          value: ref.watch(scoutProvider(widget.leagueId)),
          onRetry: () => ref.invalidate(scoutProvider(widget.leagueId)),
          data: (loaded) {
            final s = _fresh ?? loaded;
            final p = context.palette;
            final searching = s.requests.where((r) => r.searching).firstOrNull;
            Widget dropdown(String label, String? value, List<String> items, void Function(String?) on) => DropdownButtonFormField<String?>(
                  initialValue: value,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: label),
                  items: [DropdownMenuItem(value: null, child: Text(l.any)), for (final i in items) DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))],
                  onChanged: on,
                );
            return RefreshIndicator(
              color: p.gold,
              onRefresh: () {
                _fresh = null;
                ref.invalidate(scoutProvider(widget.leagueId));
                return ref.read(scoutProvider(widget.leagueId).future);
              },
              child: ListView(padding: const EdgeInsets.all(12), children: [
                GlmCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l.scoutLead, style: TextStyle(color: p.textMuted)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final (v, t) in [(null, l.anyLine), ('gk', l.lineGk), ('def', l.lineDef), ('mid', l.lineMid), ('att', l.lineAtt)])
                        ChoiceChip(label: Text(t), selected: _line == v, selectedColor: p.gold.withValues(alpha: .28), onSelected: (_) => setState(() => _line = v)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [Text(l.minOverall), const Spacer(), Text('${_min.round()}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: context.glm.goldText))]),
                    Slider(value: _min, min: 40, max: 95, divisions: 55, activeColor: p.gold, onChanged: (v) => setState(() => _min = v)),
                    Row(children: [Text(l.maxAge), const Spacer(), Text('${_age.round()}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: context.glm.goldText))]),
                    Slider(value: _age, min: 17, max: 40, divisions: 23, activeColor: p.gold, onChanged: (v) => setState(() => _age = v)),
                    dropdown(l.nationality, _nation, s.nationalities, (v) => setState(() => _nation = v)),
                    const SizedBox(height: 8),
                    dropdown(l.fromLeague, _league, s.leagues, (v) => setState(() => _league = v)),
                    const SizedBox(height: 14),
                    GlmButton(
                      label: l.askScout(money(context, s.cost), s.hours),
                      block: true,
                      loading: _busy && searching == null,
                      onPressed: searching != null || _busy
                          ? null
                          : () => _run(() => repo.ask(widget.leagueId, {
                                'min_overall': _min.round(), 'max_age': _age.round(),
                                'line': ?_line, 'nationality': ?_nation, 'league': ?_league,
                              })),
                    ),
                  ]),
                ),
                if (searching != null) ...[
                  const SizedBox(height: 12),
                  GlmCard(
                    gold: true,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(l.searching(searching.finishesAt == null ? '' : when(context, searching.finishesAt!.toLocal())), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      GlmButton(
                        label: l.finishNow(s.finishCoins),
                        variant: GlmButtonVariant.outline,
                        onPressed: _busy
                            ? null
                            : () async {
                                if (await confirm(context, l.finishNowConfirm(s.finishCoins))) await _run(() => repo.finishNow(widget.leagueId));
                              },
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 12),
                if (s.requests.any((r) => !r.searching)) SectionTitle(l.scoutReports),
                for (final r in s.requests.where((r) => !r.searching))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlmCard(
                      padding: const EdgeInsets.all(8),
                      child: r.players.isEmpty
                          ? Padding(padding: const EdgeInsets.all(8), child: Text(l.nobodyFound, style: TextStyle(color: p.textMuted)))
                          : Column(children: [
                              for (final e in r.players)
                                ListTile(
                                  dense: true,
                                  title: Text(e.player.name, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Text('${e.player.position} · ${e.player.age} · ${e.player.overall}/${e.player.potential ?? '-'} · ${e.player.nationality ?? ''}'),
                                  trailing: switch (e.state) {
                                    'available' => Text(money(context, e.player.price), textDirection: TextDirection.ltr,
                                        style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 17, color: context.glm.goldText)),
                                    'mine' => Text(l.stateMine, style: TextStyle(color: context.glm.successText, fontWeight: FontWeight.w700)),
                                    _ => Text(l.stateGone, style: TextStyle(color: p.textMuted)),
                                  },
                                  onTap: e.state != 'available'
                                      ? null
                                      : () async {
                                          final bought = await showModalBottomSheet<bool>(
                                            context: context,
                                            isScrollControlled: true,
                                            showDragHandle: true,
                                            builder: (_) => BuySheet(player: e.player, leagueId: widget.leagueId, repo: ref.read(marketRepositoryProvider)),
                                          );
                                          if (bought == true) {
                                            _fresh = null;
                                            ref.invalidate(scoutProvider(widget.leagueId));
                                          }
                                        },
                                ),
                            ]),
                    ),
                  ),
                const SizedBox(height: 24),
              ]),
            );
          },
        ),
      ),
    );
  }
}
