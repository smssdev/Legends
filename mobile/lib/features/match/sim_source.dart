import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../core/hash.dart';
import 'match_data.dart';

/// [Sprint 61 F10] A simulator match (`/sim/matches/{id}`, a ULID) played on the live match screen, as a league match:
/// its minutes, its scenes and the coach's orders. The screen keys its matches by number, so a sim match has a
/// negative one ([SimMatches.handle]); [matchSourceProvider] gives the screen this source for it.
class SimMatches {
  static final Map<int, ({String id, String? seat})> _byHandle = {};

  /// The screen's number for the sim match [id] played from [seat] (a live match between friends) or none (solo).
  static int handle(String id, String? seat) {
    final h = -(int.parse(fnv64('$id ${seat ?? ''}').substring(0, 7), radix: 16) + 1);
    _byHandle[h] = (id: id, seat: seat);
    return h;
  }

  static ({String id, String? seat})? of(int handle) => _byHandle[handle];
}

/// The sim match's API in the shape of a league match's: [show] as MatchView, [live] as LiveSync, [order] with the
/// coach's side. A solo match (against the computer) is paced here: each [live] asks the server for the next minute
/// and says to ask again when that minute has played (the web's solo page does the same).
class SimMatchRepository extends MatchRepository {
  SimMatchRepository(this._sim, this.handle, this.id, this.seat) : super(_sim);

  final ApiClient _sim;
  final int handle;
  final String id;
  final String? seat;

  bool _solo = true;
  String? _you;
  int _tickMs = 3000;

  Map<String, String>? get _seat => seat == null ? null : {'X-Seat': seat!};

  @override
  Future<MatchView> show(int _) async {
    final j = await _sim.get('/sim/matches/$id', headers: _seat);
    final r = JsonReader(j, 'MatchView');
    _solo = r.stringOrNull('mode') != 'live';
    final control = j['control'];
    // Solo: the coach holds the side he controls (home, the setup's own club).
    _you = r.stringOrNull('you') ?? (_solo && control is Map<String, dynamic> && control['home'] == 'me' ? 'home' : null);
    final view = MatchView.fromJson({...j, 'id': handle, 'league_id': 0, 'you': _you});
    _tickMs = view.tickMs;
    return view;
  }

  @override
  Future<LiveSync> live(int _, int since) async {
    if (!_solo) return LiveSync.fromJson(await _sim.get('/sim/matches/$id/live', query: {'since': since}, headers: _seat));
    final r = JsonReader(await _sim.post('/sim/matches/$id/ticks', {'count': 1}), 'SimTicks');
    final ticks = r.list('ticks', LiveTick.fromJson);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (ticks.isEmpty) return LiveSync(finished: true, tick: since, serverNow: now);
    final t = ticks.last;
    return LiveSync(finished: t.finished, tick: t.tick, serverNow: now, ticks: ticks, pollMs: t.moment?.ms ?? _tickMs);
  }

  @override
  Future<void> order(int _, Map<String, Object> order, {required String key}) =>
      _sim.post('/sim/matches/$id/actions', {...order, 'team': ?_you, 'idempotency_key': key}, _seat);

  @override
  Future<void> react(int _, String key, {String? target}) => _sim.post('/sim/matches/$id/reactions', {'key': key}, _seat);

  /// No break to be ready in and no side chat in a sim match: the screen does not offer them.
  @override
  Future<void> ready(int _) async => throw UnsupportedError('a sim match has no ready');

  @override
  Future<void> say(int _, String body) async => throw UnsupportedError('a sim match has no side chat');
}

/// The source of the match the live screen shows: a sim match's for a negative number, the league's otherwise.
final matchSourceProvider = Provider.family<MatchRepository, int>((ref, id) {
  final sim = SimMatches.of(id);
  if (sim == null) return ref.watch(matchRepositoryProvider);
  return SimMatchRepository(ref.watch(apiProvider), id, sim.id, sim.seat);
});
