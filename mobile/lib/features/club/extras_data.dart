import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';

/// [Sprint 18 F1] The club's other screens: training (Sprint 27), the specialists (Sprint 31), the spy (Sprint 30),
/// the weekly quests (Sprint 20 B5) and the league's honours. Every number and price comes from the server.
class Trainee {
  const Trainee({
    required this.id,
    required this.name,
    required this.position,
    required this.line,
    required this.age,
    required this.overall,
    required this.bonus,
    required this.potential,
    required this.progress,
    required this.sessions,
    this.injured = false,
    this.maxed = false,
  });

  factory Trainee.fromJson(Map<String, dynamic> j) => Trainee(
    id: j['id'] as int,
    name: '${j['name']}',
    position: '${j['position'] ?? ''}',
    line: '${j['line'] ?? 'mid'}',
    age: j['age'] as int? ?? 0,
    overall: j['overall'] as int? ?? 0,
    bonus: j['training_bonus'] as int? ?? 0,
    potential: j['potential'] as int? ?? 0,
    progress: j['progress'] as int? ?? 0,
    sessions: j['sessions'] as int? ?? 1,
    injured: j['injured'] == true,
    maxed: j['maxed'] == true,
  );

  final int id, age, overall, bonus, potential, progress, sessions;
  final String name, position, line;
  final bool injured, maxed;

  int get rating => overall + bonus;
}

class TrainingSlot {
  const TrainingSlot({
    required this.line,
    this.player,
    required this.sessionsDone,
    this.nextAt,
    required this.coachName,
    required this.coachStars,
  });

  factory TrainingSlot.fromJson(Map<String, dynamic> j) {
    final c = j['coach'] as Map<String, dynamic>? ?? const {};
    return TrainingSlot(
      line: '${j['line']}',
      player: j['player'] is Map<dynamic, dynamic> ? Trainee.fromJson(j['player'] as Map<String, dynamic>) : null,
      sessionsDone: j['sessions_done'] as int? ?? 0,
      nextAt: DateTime.tryParse('${j['next_at'] ?? ''}'),
      coachName: '${c['name'] ?? ''}',
      coachStars: c['hired'] == true ? c['stars'] as int? ?? 0 : 0,
    );
  }

  final String line, coachName;
  final Trainee? player;
  final int sessionsDone, coachStars;
  final DateTime? nextAt;
}

class TrainingView {
  const TrainingView({
    required this.cost,
    required this.intervalMinutes,
    required this.slots,
    required this.players,
    required this.recommended,
  });

  factory TrainingView.fromJson(Map<String, dynamic> j) => TrainingView(
    cost: (j['cost'] as num?)?.toInt() ?? 0,
    intervalMinutes: j['interval_minutes'] as int? ?? 0,
    slots: [for (final s in (j['slots'] as List<dynamic>? ?? const [])) TrainingSlot.fromJson(s as Map<String, dynamic>)],
    players: [for (final p in (j['players'] as List<dynamic>? ?? const [])) Trainee.fromJson(p as Map<String, dynamic>)],
    recommended: {
      for (final e in ((j['recommended'] as Map<dynamic, dynamic>?) ?? const {}).entries)
        if (e.value is num) '${e.key}': (e.value as num).toInt(),
    },
  );

  final int cost, intervalMinutes;
  final List<TrainingSlot> slots;
  final List<Trainee> players;
  final Map<String, int> recommended;
}

class Specialist {
  const Specialist({required this.type, required this.name, required this.offers, required this.stars, this.endsAt});

  factory Specialist.fromJson(Map<String, dynamic> j) => Specialist(
    type: '${j['type']}',
    name: '${j['name']}',
    stars: j['stars'] as int? ?? 0,
    endsAt: DateTime.tryParse('${j['ends_at'] ?? ''}'),
    offers: [
      for (final o in (j['offers'] as List<dynamic>? ?? const []))
        (
          stars: (o as Map<dynamic, dynamic>)['stars'] as int,
          cost: (o['cost'] as num).toInt(),
          currency: '${o['currency'] ?? 'coins'}',
          effect: '${o['effect'] ?? ''}',
        ),
    ],
  );

  final String type, name;
  final int stars;
  final DateTime? endsAt;
  final List<({int stars, int cost, String currency, String effect})> offers;
}

class SpyView {
  const SpyView({required this.cost, required this.currency, this.opponent, this.lockAt, this.report});

  factory SpyView.fromJson(Map<String, dynamic> j) {
    final f = j['fixture'] as Map<String, dynamic>?;
    return SpyView(
      cost: (j['cost'] as num?)?.toInt() ?? 0,
      currency: '${j['currency'] ?? 'coins'}',
      opponent: f?['opponent'] as String?,
      lockAt: DateTime.tryParse('${f?['lock_at'] ?? ''}'),
      report: j['report'] as Map<String, dynamic>?,
    );
  }

  final int cost;
  final String currency;
  final String? opponent;
  final DateTime? lockAt;
  final Map<String, dynamic>? report;
}

class Quest {
  const Quest({
    required this.quest,
    required this.progress,
    required this.target,
    required this.coins,
    required this.money,
    required this.complete,
    required this.claimed,
  });

  factory Quest.fromJson(Map<String, dynamic> j) {
    final r = j['reward'] as Map<dynamic, dynamic>? ?? const {};
    return Quest(
      quest: '${j['quest']}',
      progress: j['progress'] as int? ?? 0,
      target: j['target'] as int? ?? 1,
      coins: (r['coins'] as num?)?.toInt() ?? 0,
      money: (r['money'] as num?)?.toInt() ?? 0,
      complete: j['complete'] == true,
      claimed: j['claimed'] == true,
    );
  }

  final String quest;
  final int progress, target, coins, money;
  final bool complete, claimed;
}

class ExtrasRepository {
  ExtrasRepository(this._api);

  final ApiClient _api;

  Future<TrainingView> training(int league) async => TrainingView.fromJson(await _api.get('/leagues/$league/training'));
  Future<TrainingView> train(int league, int player, {bool replace = false}) async =>
      TrainingView.fromJson(await _api.post('/leagues/$league/training', {'player_id': player, if (replace) 'replace': true}));
  Future<TrainingView> stopTraining(int league, String line) async =>
      TrainingView.fromJson(await _api.delete('/leagues/$league/training/$line'));
  Future<TrainingView> finishTraining(int league, String line) async =>
      TrainingView.fromJson(await _api.post('/leagues/$league/training/$line/finish'));

  Future<({int days, List<Specialist> list})> specialists(int league) async {
    final j = await _api.get('/leagues/$league/specialists');
    return (
      days: j['days'] as int? ?? 0,
      list: [for (final s in (j['specialists'] as List<dynamic>? ?? const [])) Specialist.fromJson(s as Map<String, dynamic>)],
    );
  }

  Future<void> hire(int league, String type, int stars) => Intents.run(
    'specialist:$league:$type:$stars',
    (key) => _api.post('/leagues/$league/specialists', {'type': type, 'stars': stars, 'idempotency_key': key}),
  );

  Future<SpyView> spy(int league) async => SpyView.fromJson(await _api.get('/leagues/$league/spy'));
  Future<SpyView> sendSpy(int league) async => SpyView.fromJson(await _api.post('/leagues/$league/spy'));

  Future<({DateTime? renewsAt, List<Quest> quests})> quests(int league) async {
    final j = await _api.get('/leagues/$league/quests');
    return (
      renewsAt: DateTime.tryParse('${j['renews_at'] ?? ''}'),
      quests: [for (final q in (j['quests'] as List<dynamic>? ?? const [])) Quest.fromJson(q as Map<String, dynamic>)],
    );
  }

  Future<void> claimQuest(int league, String quest) => _api.post('/leagues/$league/quests/claim', {'quest': quest});

  Future<List<({int number, List<({String competition, int position, String club, String? coach})> titles})>> honours(int league) async => [
    for (final s in ((await _api.get('/leagues/$league/honours'))['seasons'] as List<dynamic>? ?? const []))
      (
        number: (s as Map<dynamic, dynamic>)['number'] as int,
        titles: [
          for (final t in (s['titles'] as List<dynamic>? ?? const []))
            (
              competition: '${(t as Map<dynamic, dynamic>)['competition']}',
              position: t['position'] as int? ?? 1,
              club: '${(t['club'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
              coach: (t['coach'] as Map<dynamic, dynamic>?)?['name'] as String?,
            ),
        ],
      ),
  ];

  Future<void> resign(int league) => _api.post('/leagues/$league/resign');

  /// What finishing a thing now costs, from the wallet's price list.
  Future<Map<String, int>> prices() async => {
    for (final e in (((await _api.get('/wallet'))['prices'] as Map<dynamic, dynamic>?) ?? const {}).entries)
      '${e.key}': (e.value as num).toInt(),
  };
}

final extrasRepositoryProvider = Provider<ExtrasRepository>((ref) => ExtrasRepository(ref.watch(apiProvider)));
final trainingProvider = FutureProvider.autoDispose.family<TrainingView, int>((ref, l) => ref.read(extrasRepositoryProvider).training(l));
final specialistsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(extrasRepositoryProvider).specialists(l));
final spyProvider = FutureProvider.autoDispose.family<SpyView, int>((ref, l) => ref.read(extrasRepositoryProvider).spy(l));
final questsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(extrasRepositoryProvider).quests(l));
final honoursProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(extrasRepositoryProvider).honours(l));
final pricesProvider = FutureProvider.autoDispose((ref) => ref.read(extrasRepositoryProvider).prices());
