import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';

/// [Sprint 50] The new things the server decides, read and asked for by the console's screens: today's tasks, the
/// league's auctions, a coach's player's release clause, the talk with a computer club, the store's chests, a timeout
/// in a live match, and a reaction on a group message. No rule lives here: every number comes from the server.

class DailyTask {
  const DailyTask({required this.task, required this.complete, required this.claimed, required this.coins});

  factory DailyTask.fromJson(Map<String, dynamic> j) =>
      DailyTask(task: '${j['task']}', complete: j['complete'] == true, claimed: j['claimed'] == true, coins: (j['coins'] as num?)?.toInt() ?? 0);

  final String task;
  final bool complete, claimed;
  final int coins;
}

class DailyTasks {
  const DailyTasks({required this.done, required this.total, required this.tasks, this.renewsAt});

  factory DailyTasks.fromJson(Map<String, dynamic> j) => DailyTasks(
        done: (j['done'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        renewsAt: DateTime.tryParse('${j['renews_at'] ?? ''}'),
        tasks: [for (final t in (j['tasks'] as List? ?? const [])) DailyTask.fromJson(t as Map<String, dynamic>)],
      );

  final int done, total;
  final DateTime? renewsAt;
  final List<DailyTask> tasks;
}

class Auction {
  const Auction({required this.playerId, required this.name, required this.position, required this.age, required this.overall, required this.value,
      required this.clubId, required this.club, required this.opening, required this.top, required this.bids, required this.next, required this.max,
      required this.mine, required this.leading, required this.endsAt});

  factory Auction.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return Auction(
      playerId: n('player_id'), name: '${j['name']}', position: '${j['position'] ?? ''}', age: n('age'), overall: n('overall'), value: n('value'),
      clubId: n('club_id'), club: '${j['club'] ?? ''}', opening: n('opening'), top: (j['top'] as num?)?.toInt(), bids: n('bids'),
      next: n('next'), max: n('max'), mine: (j['mine'] as num?)?.toInt(), leading: j['leading'] == true,
      endsAt: DateTime.tryParse('${j['ends_at'] ?? ''}') ?? DateTime.now(),
    );
  }

  final int playerId, age, overall, value, clubId, opening, bids, next, max;
  final String name, position, club;
  final int? top, mine;
  final bool leading;
  final DateTime endsAt;
}

class Negotiation {
  const Negotiation({required this.playerId, required this.price, required this.ask, required this.round, required this.rounds, required this.status, this.bought = false});

  factory Negotiation.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return Negotiation(playerId: n('player_id'), price: n('price'), ask: n('ask'), round: n('round'), rounds: n('rounds'), status: '${j['status']}', bought: j['bought'] == true);
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

  factory Chest.fromJson(Map<String, dynamic> j) => Chest(
        chest: '${j['chest']}',
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        odds: [
          for (final o in (j['odds'] as List? ?? const []))
            ChestOdds(reward: '${(o as Map)['reward']}', amount: (o['amount'] as num?)?.toInt() ?? 0, pctBp: (o['pct_bp'] as num?)?.toInt() ?? 0),
        ],
      );

  final String chest;
  final int coins;
  final List<ChestOdds> odds;
}

class ConsoleRepository {
  ConsoleRepository(this._api);

  final ApiClient _api;

  Future<DailyTasks> dailyTasks(int league) async => DailyTasks.fromJson(await _api.get('/leagues/$league/daily-tasks'));
  Future<DailyTasks> claimTask(int league, String task) async => DailyTasks.fromJson(await _api.post('/leagues/$league/daily-tasks/claim', {'task': task}));

  Future<({List<Auction> auctions, List<int> minutes})> auctions(int league) async {
    final j = await _api.get('/leagues/$league/auctions');
    return (
      auctions: [for (final a in (j['auctions'] as List? ?? const [])) Auction.fromJson(a as Map<String, dynamic>)],
      minutes: [for (final m in (j['minutes'] as List? ?? const [])) (m as num).toInt()],
    );
  }

  Future<Auction> bid(int league, int player, int amount) => Intents.run('bid:$league:$player:$amount', (key) async {
        final j = await _api.post('/leagues/$league/auctions/$player/bids', {'amount': amount, 'idempotency_key': key});
        return Auction.fromJson(j['auction'] as Map<String, dynamic>);
      });

  Future<void> listAuction(int league, int player, int price, int minutes) =>
      _api.post('/leagues/$league/transfers/listings', {'player_id': player, 'price': price, 'auction_minutes': minutes});

  Future<({int clause, String club, bool can, String? why})> releaseQuote(int league, int player) async {
    final j = await _api.get('/leagues/$league/release/$player');
    return (clause: (j['clause'] as num?)?.toInt() ?? 0, club: '${(j['club'] as Map?)?['name'] ?? ''}', can: j['can'] == true, why: j['why'] as String?);
  }

  Future<void> payRelease(int league, int player) =>
      Intents.run('release:$league:$player', (key) => _api.post('/leagues/$league/release/$player', {'idempotency_key': key}));

  Future<Negotiation> negotiation(int league, int player) async => Negotiation.fromJson(await _api.get('/leagues/$league/negotiations/$player'));

  Future<Negotiation> offer(int league, int player, int amount) => Intents.run('negotiate:$league:$player:$amount',
      (key) async => Negotiation.fromJson(await _api.post('/leagues/$league/negotiations/$player', {'amount': amount, 'idempotency_key': key})));

  Future<List<Chest>> chests(int league) async =>
      [for (final c in ((await _api.get('/leagues/$league/chests'))['chests'] as List? ?? const [])) Chest.fromJson(c as Map<String, dynamic>)];

  /// Opens a chest: what it gave ({reward, amount}).
  Future<({String reward, int amount})> openChest(int league, String chest) => Intents.run('chest:$league:$chest', (key) async {
        final o = (await _api.post('/leagues/$league/chests/$chest/open', {'idempotency_key': key}))['opened'] as Map;
        return (reward: '${o['reward']}', amount: (o['amount'] as num?)?.toInt() ?? 0);
      });

  /// The coach's one timeout in a live match: when play goes on (ms since the epoch).
  Future<int> timeout(int match) async => ((await _api.post('/matches/$match/timeout'))['timeout'] as Map)['until'] as int;

  /// A reaction on a group message (the same again, or null, takes it back): the message's counts after it.
  Future<Map<String, int>> react(int group, int message, String? reaction) async {
    final m = (await _api.post('/groups/$group/messages/$message/reaction', {'reaction': reaction}))['message'] as Map;
    return {for (final e in ((m['reactions'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num).toInt()};
  }
}

final consoleRepositoryProvider = Provider<ConsoleRepository>((ref) => ConsoleRepository(ref.watch(apiProvider)));
final dailyTasksProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(consoleRepositoryProvider).dailyTasks(l));
final auctionsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(consoleRepositoryProvider).auctions(l));
final chestsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(consoleRepositoryProvider).chests(l));
