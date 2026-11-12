import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

/// [Sprint 17 F1] My team as the API gives it (`/team`): the squad with each player's numbers, the lineup (formation,
/// eleven in slot order, the bench) and the takers.
class Player {
  const Player({required this.id, required this.name, required this.position, required this.line, required this.age, required this.overall,
      required this.potential, required this.value, required this.fitness, required this.available, required this.role,
      this.injured = 0, this.suspended = 0, this.attributes = const {}, this.nationality, this.nationCode, this.nationColors = const []});

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: j['id'] as int, name: '${j['name']}', position: '${j['position']}', line: '${j['line']}', age: j['age'] as int? ?? 0,
        overall: (j['overall'] as int? ?? 0) + (j['training_bonus'] as int? ?? 0), potential: j['potential'] as int? ?? 0,
        value: j['value'] as int? ?? 0, fitness: j['fitness'] as int? ?? 100, available: j['available'] != false, role: '${j['role'] ?? 'reserve'}',
        injured: j['injured_matches'] as int? ?? 0, suspended: j['suspended_matches'] as int? ?? 0, nationality: j['nationality'] as String?,
        nationCode: (j['nation'] as Map<dynamic, dynamic>?)?['code'] as String?, nationColors: [for (final c in ((j['nation'] as Map<dynamic, dynamic>?)?['colors'] as List<dynamic>? ?? const [])) '$c'],
        attributes: {for (final e in ((j['attributes'] as Map<dynamic, dynamic>?) ?? const {}).entries) '${e.key}': (e.value as num).toInt()},
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
  const Slot({required this.role, required this.line, required this.x, required this.y});

  factory Slot.fromJson(Map<String, dynamic> j) => Slot(role: '${j['role']}', line: '${j['line']}', x: (j['x'] as num).toInt(), y: (j['y'] as num).toInt());

  final String role, line;

  /// On the pitch: x along its length from my goal (0) forward, y across (0 to 680).
  final int x, y;
}

class Lineup {
  const Lineup({required this.formation, required this.auto, required this.slots, required this.starters, required this.bench});

  factory Lineup.fromJson(Map<String, dynamic> j) => Lineup(
        formation: '${j['formation']}', auto: j['auto'] == true,
        slots: [for (final s in j['slots'] as List<dynamic>) Slot.fromJson(s as Map<String, dynamic>)],
        starters: [for (final id in j['starters'] as List<dynamic>) id as int], bench: [for (final id in j['bench'] as List<dynamic>) id as int],
      );

  final String formation;
  final bool auto;
  final List<Slot> slots;
  final List<int> starters, bench;
}

class TeamData {
  const TeamData({required this.players, required this.lineup, required this.morale, required this.squadValue, this.lines = const {}, this.captain});

  factory TeamData.fromJson(Map<String, dynamic> j) => TeamData(
        players: [for (final p in j['players'] as List<dynamic>) Player.fromJson(p as Map<String, dynamic>)],
        lineup: Lineup.fromJson(j['lineup'] as Map<String, dynamic>),
        morale: (j['morale'] as Map<dynamic, dynamic>?)?['value'] as int? ?? 70, squadValue: j['squad_value'] as int? ?? 0,
        lines: {for (final e in ((j['lines'] as Map<dynamic, dynamic>?) ?? const {}).entries) '${e.key}': (e.value as num).toInt()},
        captain: ((j['takers'] as Map<dynamic, dynamic>?)?['captain'] as Map<dynamic, dynamic>?)?['player_id'] as int?,
      );

  final List<Player> players;
  final Lineup lineup;
  final int morale, squadValue;

  /// [Sprint 46] Each line's rating (gk, def, mid, att, the server's) and the captain.
  final Map<String, int> lines;
  final int? captain;

  Player? byId(int id) => players.where((p) => p.id == id).firstOrNull;
}

class Formation {
  const Formation({required this.name, required this.label, required this.slots});

  factory Formation.fromJson(Map<String, dynamic> j) =>
      Formation(name: '${j['name']}', label: '${j['label'] ?? j['name']}', slots: [for (final s in j['slots'] as List<dynamic>) Slot.fromJson(s as Map<String, dynamic>)]);

  final String name, label;
  final List<Slot> slots;
}

/// The engine's own tactics keys (docs/ENGINE.md 5): the plan, the tackling, three sliders, the three lines, the trap
/// and the marking.
class Tactics {
  const Tactics(this.values, {this.preset, this.presets = const []});

  factory Tactics.fromJson(Map<String, dynamic> j) => Tactics(Map<String, Object>.from(j['tactics'] as Map<dynamic, dynamic>),
      preset: j['preset'] as String?, presets: [for (final p in (j['presets'] as List<dynamic>? ?? const [])) '$p']);

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
  Future<List<Formation>> formations() async => [for (final f in (await _api.get('/data/formations'))['formations'] as List<dynamic>) Formation.fromJson(f as Map<String, dynamic>)];
  /// [positions] the ten outfield places [x, y] (the keeper stays in goal); without them the server goes back to the
  /// formation's own places.
  Future<TeamData> saveLineup(int league, String formation, List<int> starters, List<int> bench, {List<List<int>>? positions}) async =>
      TeamData.fromJson(await _api.put('/leagues/$league/team/lineup',
          {'formation': formation, 'starters': starters, 'bench': bench, 'positions': ?positions}));
  Future<TeamData> autoLineup(int league) async => TeamData.fromJson(await _api.delete('/leagues/$league/team/lineup'));
  Future<Tactics> tactics(int league) async => Tactics.fromJson(await _api.get('/leagues/$league/team/tactics'));
  Future<Tactics> saveTactics(int league, Map<String, Object> changes) async => Tactics.fromJson(await _api.put('/leagues/$league/team/tactics', changes));
}

final teamRepositoryProvider = Provider<TeamRepository>((ref) => TeamRepository(ref.watch(apiProvider)));
final teamProvider = FutureProvider.autoDispose.family<TeamData, int>((ref, league) => ref.read(teamRepositoryProvider).team(league));
final formationsProvider = FutureProvider<List<Formation>>((ref) => ref.read(teamRepositoryProvider).formations());
final tacticsProvider = FutureProvider.autoDispose.family<Tactics, int>((ref, league) => ref.read(teamRepositoryProvider).tactics(league));
