import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';

/// [Sprint 50] The new things the server decides, read and asked for by the console's screens: today's tasks, the
/// league's auctions, a coach's player's release clause, the talk with a computer club, the store's chests, a timeout
/// in a live match, and a reaction on a group message. No rule lives here: every number comes from the server.

class DailyTask {
  const DailyTask({required this.task, required this.complete, required this.claimed, required this.coins});

  factory DailyTask.of(api.DailyTasksTasksItem t) => DailyTask(task: t.task, complete: t.complete, claimed: t.claimed, coins: t.coins);

  final String task;
  final bool complete, claimed;
  final int coins;
}

class DailyTasks {
  const DailyTasks({required this.done, required this.total, required this.tasks, this.renewsAt});

  /// [Sprint 59 F1] Today's tasks (`DailyTasks`), read through the generated model.
  factory DailyTasks.fromJson(Object? json) {
    final d = api.DailyTasks.fromJson(json);
    return DailyTasks(
      done: d.done,
      total: d.total,
      renewsAt: DateTime.tryParse(d.renewsAt),
      tasks: [for (final t in d.tasks) DailyTask.of(t)],
    );
  }

  final int done, total;
  final DateTime? renewsAt;
  final List<DailyTask> tasks;
}

class Auction {
  const Auction({
    required this.playerId,
    required this.name,
    required this.position,
    required this.age,
    required this.overall,
    required this.value,
    required this.clubId,
    required this.club,
    required this.opening,
    required this.top,
    required this.bids,
    required this.next,
    required this.max,
    required this.mine,
    required this.leading,
    required this.endsAt,
  });

  /// [Sprint 59 F1] An auction (`Auction`), read through the generated model.
  factory Auction.fromJson(Object? json) {
    final a = api.Auction.fromJson(json);
    return Auction(
      playerId: a.playerId,
      name: a.name,
      position: a.position,
      age: a.age,
      overall: a.overall,
      value: a.value,
      clubId: a.clubId,
      club: a.club,
      opening: a.opening,
      top: a.top,
      bids: a.bids,
      next: a.next,
      max: a.max,
      mine: a.mine,
      leading: a.leading,
      endsAt: DateTime.parse(a.endsAt),
    );
  }

  final int playerId, age, overall, value, clubId, opening, bids, next, max;
  final String name, position, club;
  final int? top, mine;
  final bool leading;
  final DateTime endsAt;
}

class Negotiation {
  const Negotiation({
    required this.playerId,
    required this.price,
    required this.ask,
    required this.round,
    required this.rounds,
    required this.status,
    this.bought = false,
  });

  /// [Sprint 59 F1] The talk with a computer club (`Negotiation`), read through the generated model.
  factory Negotiation.fromJson(Object? json) {
    final n = api.Negotiation.fromJson(json);
    return Negotiation(
      playerId: n.playerId,
      price: n.price,
      ask: n.ask,
      round: n.round,
      rounds: n.rounds,
      status: n.status,
      bought: n.bought ?? false,
    );
  }

  final int playerId, price, ask, round, rounds;
  final String status;
  final bool bought;
}

class ChestOdds {
  const ChestOdds({required this.reward, required this.amount, required this.pctBp});

  final String reward;
  final int amount, pctBp;
}

class Chest {
  const Chest({required this.chest, required this.coins, required this.odds});

  /// [Sprint 59 F1] A chest and its odds (`Chest`), read through the generated model.
  factory Chest.fromJson(Object? json) {
    final c = api.Chest.fromJson(json);
    return Chest(
      chest: c.chest,
      coins: c.coins,
      odds: [for (final o in c.odds) ChestOdds(reward: o.reward, amount: o.amount, pctBp: o.pctBp)],
    );
  }

  final String chest;
  final int coins;
  final List<ChestOdds> odds;
}

class ConsoleRepository {
  ConsoleRepository(this._api);

  final ApiClient _api;

  Future<DailyTasks> dailyTasks(int league) async => DailyTasks.fromJson(await _api.get('/leagues/$league/daily-tasks'));
  Future<DailyTasks> claimTask(int league, String task) async =>
      DailyTasks.fromJson(await _api.post('/leagues/$league/daily-tasks/claim', {'task': task}));

  Future<({List<Auction> auctions, List<int> minutes})> auctions(int league) async {
    final r = JsonReader(await _api.get('/leagues/$league/auctions'), 'Auctions');
    return (auctions: r.list('auctions', Auction.fromJson), minutes: r.list('minutes', JsonReader.intOf));
  }

  Future<Auction> bid(int league, int player, int amount) => Intents.run('bid:$league:$player:$amount', (key) async {
    final j = await _api.post('/leagues/$league/auctions/$player/bids', {'amount': amount, 'idempotency_key': key});
    return JsonReader(j, 'Bid').object('auction', Auction.fromJson);
  });

  Future<void> listAuction(int league, int player, int price, int minutes) =>
      _api.post('/leagues/$league/transfers/listings', {'player_id': player, 'price': price, 'auction_minutes': minutes});

  Future<({int clause, String club, bool can, String? why})> releaseQuote(int league, int player) async {
    final q = api.LeaguesReleaseByPlayerAnswer.fromJson(await _api.get('/leagues/$league/release/$player'));
    return (clause: q.clause, club: q.club.name ?? '', can: q.can, why: q.why);
  }

  Future<void> payRelease(int league, int player) =>
      Intents.run('release:$league:$player', (key) => _api.post('/leagues/$league/release/$player', {'idempotency_key': key}));

  Future<Negotiation> negotiation(int league, int player) async =>
      Negotiation.fromJson(await _api.get('/leagues/$league/negotiations/$player'));

  Future<Negotiation> offer(int league, int player, int amount) => Intents.run(
    'negotiate:$league:$player:$amount',
    (key) async =>
        Negotiation.fromJson(await _api.post('/leagues/$league/negotiations/$player', {'amount': amount, 'idempotency_key': key})),
  );

  Future<List<Chest>> chests(int league) async => [
    ...JsonReader(await _api.get('/leagues/$league/chests'), 'Chests').list('chests', Chest.fromJson),
  ];

  /// Opens a chest: what it gave ({reward, amount}).
  Future<({String reward, int amount})> openChest(int league, String chest) => Intents.run('chest:$league:$chest', (key) async {
    final j = await _api.post('/leagues/$league/chests/$chest/open', {'idempotency_key': key});
    return JsonReader(j, 'ChestOpen').object('opened', (o) {
      final r = JsonReader(o, 'ChestOpened');
      return (reward: r.string('reward'), amount: r.int_('amount'));
    });
  });

  /// The coach's one timeout in a live match: when play goes on (ms since the epoch).
  Future<int> timeout(int match) async =>
      JsonReader(await _api.post('/matches/$match/timeout'), 'Timeout').object('timeout', api.MatchTimeout.fromJson).until;

  /// A reaction on a group message (the same again, or null, takes it back): the message's counts after it.
  Future<Map<String, int>> react(int group, int message, String? reaction) async {
    final j = await _api.post('/groups/$group/messages/$message/reaction', {'reaction': reaction});
    return JsonReader(j, 'Reacted').object('message', api.ChatMessage.fromJson).reactions ?? const {};
  }
}

final consoleRepositoryProvider = Provider<ConsoleRepository>((ref) => ConsoleRepository(ref.watch(apiProvider)));
final dailyTasksProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(consoleRepositoryProvider).dailyTasks(l));
final auctionsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(consoleRepositoryProvider).auctions(l));
final chestsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(consoleRepositoryProvider).chests(l));
