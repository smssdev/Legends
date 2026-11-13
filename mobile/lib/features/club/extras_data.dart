import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
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

  /// [Sprint 59 F1] From the generated model.
  factory Trainee.of(api.TrainingPlayer p) => Trainee(
    id: p.id,
    name: p.name,
    position: p.position,
    line: p.line,
    age: p.age,
    overall: p.overall,
    bonus: p.trainingBonus,
    potential: p.potential,
    progress: p.progress,
    sessions: p.sessions,
    injured: p.injured,
    maxed: p.maxed,
  );

  final int id, age, overall, bonus, potential, progress, sessions;
  final String name, position, line;
  final bool injured, maxed;

  /// [Sprint 59 F1] The server's overall already has the training on top (TrainingController): adding the bonus
  /// again showed a trained player higher than he is.
  int get rating => overall;
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

  factory TrainingSlot.of(api.TrainingViewSlotsItem s) => TrainingSlot(
    line: s.line,
    player: s.player == null ? null : Trainee.of(s.player!),
    sessionsDone: s.sessionsDone,
    nextAt: DateTime.tryParse(s.nextAt ?? ''),
    coachName: s.coach.name,
    coachStars: s.coach.hired ? s.coach.stars : 0,
  );

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

  /// [Sprint 59 F1] Training (`TrainingView`), read through its generated model.
  factory TrainingView.fromJson(Object? json) {
    final v = api.TrainingView.fromJson(json);
    final r = v.recommended;
    return TrainingView(
      cost: v.cost,
      intervalMinutes: v.intervalMinutes,
      slots: [for (final s in v.slots) TrainingSlot.of(s)],
      players: [for (final p in v.players) Trainee.of(p)],
      recommended: {'gk': ?r.gk, 'def': ?r.def, 'mid': ?r.mid, 'att': ?r.att},
    );
  }

  final int cost, intervalMinutes;
  final List<TrainingSlot> slots;
  final List<Trainee> players;
  final Map<String, int> recommended;
}

class Specialist {
  const Specialist({required this.type, required this.name, required this.offers, required this.stars, this.endsAt});

  factory Specialist.of(api.SpecialistsViewSpecialistsItem s) => Specialist(
    type: s.type,
    name: s.name,
    stars: s.stars,
    endsAt: DateTime.tryParse(s.endsAt ?? ''),
    offers: [for (final o in s.offers) (stars: o.stars, cost: o.cost, currency: o.currency, effect: o.effect)],
  );

  final String type, name;
  final int stars;
  final DateTime? endsAt;
  final List<({int stars, int cost, String currency, String effect})> offers;
}

class SpyView {
  const SpyView({required this.cost, required this.currency, this.opponent, this.lockAt, this.report});

  /// [Sprint 59 F1] The spy and his report (`SpyView`, `SpyViewReport`), read through the generated model.
  factory SpyView.fromJson(Object? json) {
    final v = api.SpyView.fromJson(json);
    return SpyView(
      cost: v.cost,
      currency: v.currency,
      opponent: v.fixture?.opponent,
      lockAt: DateTime.tryParse(v.fixture?.lockAt ?? ''),
      report: v.report,
    );
  }

  final int cost;
  final String currency;
  final String? opponent;
  final DateTime? lockAt;
  final api.SpyViewReport? report;
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

  factory Quest.of(api.QuestsQuestsItem q) => Quest(
    quest: q.quest,
    progress: q.progress,
    target: q.target,
    coins: q.reward.coins ?? 0,
    money: q.reward.money ?? 0,
    complete: q.complete,
    claimed: q.claimed,
  );

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

  Future<({int days, List<Specialist> list})> specialists(int league) async =>
      readSpecialists(await _api.get('/leagues/$league/specialists'));

  /// [Sprint 59 F1] The specialists (`SpecialistsView`) through their generated model.
  static ({int days, List<Specialist> list}) readSpecialists(Object? json) {
    final v = api.SpecialistsView.fromJson(json);
    return (days: v.days, list: [for (final s in v.specialists) Specialist.of(s)]);
  }

  Future<void> hire(int league, String type, int stars) => Intents.run(
    'specialist:$league:$type:$stars',
    (key) => _api.post('/leagues/$league/specialists', {'type': type, 'stars': stars, 'idempotency_key': key}),
  );

  Future<SpyView> spy(int league) async => SpyView.fromJson(await _api.get('/leagues/$league/spy'));
  Future<SpyView> sendSpy(int league) async => SpyView.fromJson(await _api.post('/leagues/$league/spy'));

  Future<({DateTime? renewsAt, List<Quest> quests})> quests(int league) async => readQuests(await _api.get('/leagues/$league/quests'));

  /// [Sprint 59 F1] The week's quests (`Quests`) through their generated model.
  static ({DateTime? renewsAt, List<Quest> quests}) readQuests(Object? json) {
    final v = api.Quests.fromJson(json);
    return (renewsAt: DateTime.tryParse(v.renewsAt), quests: [for (final q in v.quests) Quest.of(q)]);
  }

  Future<void> claimQuest(int league, String quest) => _api.post('/leagues/$league/quests/claim', {'quest': quest});

  Future<List<({int number, List<({String competition, int position, String club, String? coach})> titles})>> honours(int league) async => [
    for (final s in api.Honours.fromJson(await _api.get('/leagues/$league/honours')).seasons)
      (
        number: s.number,
        titles: [for (final t in s.titles) (competition: t.competition, position: t.position, club: t.club.name, coach: t.coach?.name)],
      ),
  ];

  Future<void> resign(int league) => _api.post('/leagues/$league/resign');

  /// What finishing a thing now costs, from the wallet's price list.
  Future<Map<String, int>> prices() async => api.WalletView.fromJson(await _api.get('/wallet')).prices;
}

final extrasRepositoryProvider = Provider<ExtrasRepository>((ref) => ExtrasRepository(ref.watch(apiProvider)));
final trainingProvider = FutureProvider.autoDispose.family<TrainingView, int>((ref, l) => ref.read(extrasRepositoryProvider).training(l));
final specialistsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(extrasRepositoryProvider).specialists(l));
final spyProvider = FutureProvider.autoDispose.family<SpyView, int>((ref, l) => ref.read(extrasRepositoryProvider).spy(l));
final questsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(extrasRepositoryProvider).quests(l));
final honoursProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(extrasRepositoryProvider).honours(l));
final pricesProvider = FutureProvider.autoDispose((ref) => ref.read(extrasRepositoryProvider).prices());
