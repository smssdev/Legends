import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';

/// [Sprint 17 F1] My team as the API gives it (`/team`): the squad with each player's numbers, the lineup (formation,
/// eleven in slot order, the bench) and the takers.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.position,
    required this.line,
    required this.age,
    required this.overall,
    required this.potential,
    required this.value,
    required this.fitness,
    required this.available,
    required this.role,
    this.injured = 0,
    this.suspended = 0,
    this.attributes = const {},
    this.nationality,
    this.nationCode,
    this.nationColors = const [],
  });

  /// [Sprint 59 F1] A squad player from the generated model. `overall` already counts the training (the server's
  /// Training::boosted); the hand-written reader added training_bonus again, so a trained player showed higher here
  /// than on the site.
  factory Player.of(api.SquadPlayer p) => Player(
    id: p.id,
    name: p.name,
    position: p.position,
    line: p.line,
    age: p.age,
    overall: p.overall,
    potential: p.potential,
    value: p.value,
    fitness: p.fitness,
    available: p.available,
    role: p.role,
    injured: p.injuredMatches,
    suspended: p.suspendedMatches,
    nationality: p.nationality,
    nationCode: p.nation?.code,
    nationColors: p.nation?.colors ?? const [],
    attributes: {for (final e in p.attributes.entries) e.key: e.value ?? 0},
  );

  final int id, age, overall, potential, value, fitness, injured, suspended;
  final String name, position, line, role;
  final String? nationality;

  /// [Sprint 46] His national team's code and two colours (the server's Nations), for the flag chip.
  final String? nationCode;
  final List<String> nationColors;
  final bool available;
  final Map<String, int> attributes;
}

class Slot {
  const Slot({required this.role, required this.line, required this.x, required this.y, this.allowed = const []});

  /// [Sprint 59 F1] A slot from the generated model.
  factory Slot.of(api.Slot s) => Slot(role: s.role, line: s.line, x: s.x, y: s.y, allowed: s.allowed ?? const []);

  /// A slot as JSON (the tests' own), read through the generated model.
  factory Slot.fromJson(Object? json) => Slot.of(api.Slot.fromJson(json));

  final String role, line;

  /// [Sprint 59 F6] The player lines this slot takes, the server's rule (empty from an older server: nothing refused).
  final List<String> allowed;

  /// Whether a player of [playerLine] may stand here.
  bool takes(String? playerLine) => allowed.isEmpty || allowed.contains(playerLine);

  /// On the pitch: x along its length from my goal (0) forward, y across (0 to 680).
  final int x, y;
}

class Lineup {
  const Lineup({required this.formation, required this.auto, required this.slots, required this.starters, required this.bench});

  /// [Sprint 59 F1] From the generated model (an empty place reads as 0: no player).
  factory Lineup.of(api.Lineup l) => Lineup(
    formation: l.formation,
    auto: l.auto,
    slots: [for (final s in l.slots) Slot.of(s)],
    starters: [for (final id in l.starters) id ?? 0],
    bench: l.bench,
  );

  final String formation;
  final bool auto;
  final List<Slot> slots;
  final List<int> starters, bench;
}

class TeamData {
  const TeamData({
    required this.players,
    required this.lineup,
    required this.morale,
    required this.squadValue,
    this.lines = const {},
    this.captain,
    this.takers = const {},
  });

  /// [Sprint 59 F1] My team (`Team`), read through its generated model.
  factory TeamData.fromJson(Object? json) {
    final t = api.TeamAnswer.fromJson(json);
    return TeamData(
      players: [for (final p in t.players) Player.of(p)],
      lineup: Lineup.of(t.lineup),
      morale: t.morale.value,
      squadValue: t.squadValue,
      lines: {'gk': t.lines.gk, 'def': t.lines.def, 'mid': t.lines.mid, 'att': t.lines.att},
      captain: t.takers['captain']?.playerId,
      takers: {
        for (final e in t.takers.entries)
          e.key: Taker(
            playerId: e.value.playerId,
            auto: e.value.auto,
            chosenId: e.value.chosenId,
            candidates: [
              for (final c in e.value.candidates ?? const <api.TeamAnswerTakersValueCandidatesItem>[])
                (id: c.id, skill: c.skill, on: c.on_),
            ],
          ),
      },
    );
  }

  final List<Player> players;
  final Lineup lineup;
  final int morale, squadValue;

  /// [Sprint 46] Each line's rating (gk, def, mid, att, the server's) and the captain.
  final Map<String, int> lines;
  final int? captain;

  /// [Sprint 60 F4] The captain and the set-piece takers (captain, penalty, free_kick, corner), as the site's TakersPage.
  final Map<String, Taker> takers;

  Player? byId(int id) => players.where((p) => p.id == id).firstOrNull;
}

/// [Sprint 27 W5, Sprint 60 F4] One role: who takes it in the next match, whether the server picks him (auto), the
/// coach's own choice (playing or not), and the squad ranked by the role's skill (the server's).
class Taker {
  const Taker({this.playerId, required this.auto, this.chosenId, this.candidates = const []});

  final int? playerId, chosenId;
  final bool auto;
  final List<({int id, int skill, bool on})> candidates;
}

class Formation {
  const Formation({required this.name, required this.label, required this.slots});

  /// [Sprint 59 F1] From the generated model.
  factory Formation.of(api.Formation f) => Formation(name: f.name, label: f.label, slots: [for (final s in f.slots) Slot.of(s)]);

  final String name, label;
  final List<Slot> slots;
}

/// The engine's own tactics keys (docs/ENGINE.md 5): the plan, the tackling, three sliders, the three lines, the trap
/// and the marking.
class Tactics {
  const Tactics(this.values, {this.preset, this.presets = const []});

  /// [Sprint 59 F1] My tactics (`Tactics`), read through the generated model; kept as the engine's keys.
  factory Tactics.fromJson(Object? json) {
    final a = api.TacticsAnswer.fromJson(json);
    final t = a.tactics;
    return Tactics(
      {
        'plan': ?t.plan,
        'tackling': ?t.tackling,
        'pressing': ?t.pressing,
        'style': ?t.style,
        'tempo': ?t.tempo,
        'att': ?t.att,
        'mid': ?t.mid,
        'def': ?t.def,
        'trap': ?t.trap,
        'marking': ?t.marking,
      },
      preset: a.preset,
      presets: a.presets ?? const [],
    );
  }

  final Map<String, Object> values;

  /// [Sprint 50 M12] The ready philosophy the tactics match now (the server's), and the ones there are.
  final String? preset;
  final List<String> presets;
  T get<T>(String key) => values[key] as T;
  Tactics set(String key, Object v) => Tactics({...values, key: v}, presets: presets);
}

class TeamRepository {
  TeamRepository(this._api);

  final ApiClient _api;

  Future<TeamData> team(int league) async => TeamData.fromJson(await _api.get('/leagues/$league/team'));
  Future<List<Formation>> formations() async => [
    for (final f in api.DataFormationsAnswer.fromJson(await _api.get('/data/formations')).formations) Formation.of(f),
  ];

  /// [positions] the ten outfield places [x, y] (the keeper stays in goal); without them the server goes back to the
  /// formation's own places.
  Future<TeamData> saveLineup(int league, String formation, List<int> starters, List<int> bench, {List<List<int>>? positions}) async =>
      TeamData.fromJson(
        await _api.put('/leagues/$league/team/lineup', {
          'formation': formation,
          'starters': starters,
          'bench': bench,
          'positions': ?positions,
        }),
      );

  /// [Sprint 60 F4] The four roles at once ([roles]: each role's player, or null for the server's own pick).
  Future<TeamData> saveTakers(int league, Map<String, int?> roles) async =>
      TeamData.fromJson(await _api.put('/leagues/$league/team/takers', roles));
  Future<TeamData> autoLineup(int league) async => TeamData.fromJson(await _api.delete('/leagues/$league/team/lineup'));
  Future<Tactics> tactics(int league) async => Tactics.fromJson(await _api.get('/leagues/$league/team/tactics'));
  Future<Tactics> saveTactics(int league, Map<String, Object> changes) async =>
      Tactics.fromJson(await _api.put('/leagues/$league/team/tactics', changes));
}

final teamRepositoryProvider = Provider<TeamRepository>((ref) => TeamRepository(ref.watch(apiProvider)));
final teamProvider = FutureProvider.autoDispose.family<TeamData, int>((ref, league) => ref.read(teamRepositoryProvider).team(league));
final formationsProvider = FutureProvider<List<Formation>>((ref) => ref.read(teamRepositoryProvider).formations());
final tacticsProvider = FutureProvider.autoDispose.family<Tactics, int>((ref, league) => ref.read(teamRepositoryProvider).tactics(league));
