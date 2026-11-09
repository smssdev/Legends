import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';

/// [Sprint 18 F1] The market (`/leagues/{id}/market`, UP11) and the deals between coaches (`/leagues/{id}/transfers`,
/// Sprint 25): the server sets every price, floor, cap, wait and fee; the app shows them and sends the coach's choice.
class MarketPlayer {
  const MarketPlayer({required this.id, required this.name, required this.position, required this.line, required this.age, required this.overall,
      this.potential, required this.value, required this.price, this.wasPrice, this.nationality, this.sellerKind, this.sellerClub, this.sellerCoach,
      this.fits = false, this.star = false, this.attributes = const {}});

  factory MarketPlayer.fromJson(Map<String, dynamic> j) {
    final s = j['seller'] as Map<String, dynamic>?;
    return MarketPlayer(
      id: j['id'] as int, name: '${j['name']}', position: '${j['position'] ?? ''}', line: '${j['line'] ?? 'mid'}', age: j['age'] as int? ?? 0,
      overall: j['overall'] as int? ?? 0, potential: j['potential'] as int?, value: (j['value'] as num?)?.toInt() ?? 0,
      price: (j['price'] as num?)?.toInt() ?? 0, wasPrice: (j['was_price'] as num?)?.toInt(), nationality: j['nationality'] as String?,
      sellerKind: s?['kind'] as String?, sellerClub: s?['club'] as String? ?? (j['club'] as Map?)?['name'] as String?, sellerCoach: s?['coach'] as String?,
      fits: j['fits'] == true, star: j['star'] == true,
      attributes: {for (final e in ((j['attributes'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num?)?.toInt() ?? 0},
    );
  }

  final int id, age, overall, value, price;
  final int? potential, wasPrice;
  final String name, position, line;
  final String? nationality, sellerKind, sellerClub, sellerCoach;
  final bool fits, star;
  final Map<String, int> attributes;
}

class BuyQuote {
  const BuyQuote({required this.price, required this.cash, required this.docCoins, required this.short, this.compensate, required this.can, this.why});

  factory BuyQuote.fromJson(Map<String, dynamic> j) {
    final c = j['compensate'] as Map<String, dynamic>?;
    return BuyQuote(
      price: (j['price'] as num).toInt(), cash: (j['cash'] as num?)?.toInt() ?? 0, docCoins: j['doc_coins'] as int? ?? 0, short: (j['short'] as num?)?.toInt() ?? 0,
      compensate: c == null ? null : (cash: (c['cash'] as num).toInt(), coins: (c['coins'] as num).toInt()),
      can: j['can'] == true, why: j['why'] as String?,
    );
  }

  final int price, cash, docCoins, short;
  final ({int cash, int coins})? compensate;
  final bool can;
  final String? why;
}

/// One of my players and the two ways to sell him: listed (up to his cap, waiting for a buyer) or now (a fee).
class MyPlayer {
  const MyPlayer({required this.id, required this.name, required this.position, required this.line, required this.overall, required this.value,
      required this.cost, required this.floor, required this.cap, required this.quickPays, required this.quickFee, required this.waitValue, required this.waitCap,
      this.listedPrice, this.sellsAt});

  factory MyPlayer.fromJson(Map<String, dynamic> j) {
    final quick = j['quick'] as Map<String, dynamic>? ?? const {};
    final fee = quick['fee'] as Map<String, dynamic>? ?? const {};
    final wait = j['wait_hours'] as Map<String, dynamic>? ?? const {};
    final listed = j['listed'] as Map<String, dynamic>?;
    return MyPlayer(
      id: j['id'] as int, name: '${j['name']}', position: '${j['position'] ?? ''}', line: '${j['line'] ?? 'mid'}', overall: j['overall'] as int? ?? 0,
      value: (j['value'] as num?)?.toInt() ?? 0, cost: (j['cost'] as num?)?.toInt() ?? 0, floor: (j['floor'] as num?)?.toInt() ?? 0, cap: (j['cap'] as num?)?.toInt() ?? 0,
      quickPays: (quick['pays'] as num?)?.toInt() ?? 0, quickFee: (currency: '${fee['currency'] ?? 'coins'}', amount: (fee['amount'] as num?)?.toInt() ?? 0),
      waitValue: wait['value'] as int? ?? 0, waitCap: wait['cap'] as int? ?? 0,
      listedPrice: (listed?['price'] as num?)?.toInt(), sellsAt: DateTime.tryParse('${listed?['sells_at'] ?? ''}'),
    );
  }

  final int id, overall, value, cost, floor, cap, quickPays, waitValue, waitCap;
  final String name, position, line;
  final ({String currency, int amount}) quickFee;
  final int? listedPrice;
  final DateTime? sellsAt;

  bool get listed => listedPrice != null;
}

class Selling {
  const Selling({required this.mine, required this.maxListings, required this.listed, this.closed});

  factory Selling.fromJson(Map<String, dynamic> j) {
    final s = j['selling'] as Map<String, dynamic>? ?? const {};
    return Selling(
      mine: [for (final p in (j['mine'] as List? ?? const [])) MyPlayer.fromJson(p as Map<String, dynamic>)],
      maxListings: s['max_listings'] as int? ?? 4, listed: s['listed'] as int? ?? 0, closed: j['closed'] as String?,
    );
  }

  final List<MyPlayer> mine;
  final int maxListings, listed;
  final String? closed;
}

class OfferPlayer {
  const OfferPlayer({required this.id, required this.name, required this.position, required this.overall, required this.value});

  factory OfferPlayer.fromJson(Map<String, dynamic> j) => OfferPlayer(
      id: j['id'] as int, name: '${j['name']}', position: '${j['position'] ?? ''}', overall: j['overall'] as int? ?? 0, value: (j['value'] as num?)?.toInt() ?? 0);

  final int id, overall, value;
  final String name, position;
}

class Offer {
  const Offer({required this.id, required this.status, required this.money, required this.from, required this.to, required this.incoming,
      required this.players, required this.give, this.expiresAt, this.fromId = 0, this.toId = 0});

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: j['id'] as int, status: '${j['status']}', money: (j['money'] as num?)?.toInt() ?? 0,
        from: '${(j['from'] as Map?)?['name'] ?? ''}', to: '${(j['to'] as Map?)?['name'] ?? ''}', incoming: j['incoming'] == true,
        fromId: (j['from'] as Map?)?['id'] as int? ?? 0, toId: (j['to'] as Map?)?['id'] as int? ?? 0,
        players: [for (final p in (j['in'] as List? ?? const [])) OfferPlayer.fromJson(p as Map<String, dynamic>)],
        give: [for (final p in (j['out'] as List? ?? const [])) OfferPlayer.fromJson(p as Map<String, dynamic>)],
        expiresAt: DateTime.tryParse('${j['expires_at'] ?? ''}'),
      );

  final int id, money, fromId, toId;
  final String status, from, to;
  final bool incoming;

  /// From the offering club's side: the players it asks for (`in`) and those it gives (`out`).
  final List<OfferPlayer> players, give;
  final DateTime? expiresAt;

  bool get pending => status == 'pending';
}

class Deals {
  const Deals({required this.offers, required this.listings, this.closed, this.clubs = const [], this.fairMinBp = 5000, this.fairMaxBp = 20000});

  factory Deals.fromJson(Map<String, dynamic> j) => Deals(
        offers: [for (final o in (j['offers'] as List? ?? const [])) Offer.fromJson(o as Map<String, dynamic>)],
        listings: [
          for (final l in (j['listings'] as List? ?? const []))
            (player: OfferPlayer.fromJson((l as Map)['player'] as Map<String, dynamic>), price: (l['price'] as num).toInt(), club: '${(l['club'] as Map?)?['name'] ?? ''}', mine: l['mine'] == true),
        ],
        closed: j['closed'] as String?,
        clubs: [for (final c in (j['clubs'] as List? ?? const [])) (id: (c as Map)['id'] as int, name: '${c['name']}')],
        fairMinBp: ((j['fair'] as Map?)?['min_bp'] as num?)?.toInt() ?? 5000, fairMaxBp: ((j['fair'] as Map?)?['max_bp'] as num?)?.toInt() ?? 20000,
      );

  /// The coaches' clubs an offer can go to, and the fair range of a deal (its money and players against the values).
  final List<({int id, String name})> clubs;
  final int fairMinBp, fairMaxBp;
  final List<Offer> offers;
  final List<({OfferPlayer player, int price, String club, bool mine})> listings;
  final String? closed;
}

/// [X61 E2] A loan between coaches: asked, running or done; `mine` when the player is mine.
class Loan {
  const Loan({required this.id, required this.status, required this.mine, required this.player, required this.owner, required this.borrower,
      required this.rounds, required this.fee, this.untilRound});

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as int, status: '${j['status']}', mine: j['mine'] == true, player: '${(j['player'] as Map?)?['name'] ?? ''}',
        owner: '${j['owner'] ?? ''}', borrower: '${j['borrower'] ?? ''}', rounds: j['rounds'] as int? ?? 0, fee: (j['fee'] as num?)?.toInt() ?? 0,
        untilRound: j['until_round'] as int?,
      );

  final int id, rounds, fee;
  final int? untilRound;
  final String status, player, owner, borrower;
  final bool mine;

  bool get pending => status == 'pending';
}

/// [X61 E3] This period's academy prospects: the potential as a range until signed.
class Prospect {
  const Prospect({required this.id, required this.name, required this.position, required this.line, required this.age, required this.overall,
      required this.potentialFrom, required this.potentialTo, required this.price, this.nationality});

  factory Prospect.fromJson(Map<String, dynamic> j) => Prospect(
        id: j['id'] as int, name: '${j['name']}', position: '${j['position'] ?? ''}', line: '${j['line'] ?? 'mid'}', age: j['age'] as int? ?? 0,
        overall: j['overall'] as int? ?? 0, potentialFrom: j['potential_from'] as int? ?? 0, potentialTo: j['potential_to'] as int? ?? 0,
        price: (j['price'] as num?)?.toInt() ?? 0, nationality: j['nationality'] as String?,
      );

  final int id, age, overall, potentialFrom, potentialTo, price;
  final String name, position, line;
  final String? nationality;
}

class MarketRepository {
  MarketRepository(this._api);

  final ApiClient _api;

  Future<({List<MarketPlayer> players, DateTime? renewsAt, int balance, String? closed})> list(int league, String line) async {
    final j = await _api.get('/leagues/$league/market', query: {'line': line});
    return (
      players: [for (final p in (j['players'] as List? ?? const [])) MarketPlayer.fromJson(p as Map<String, dynamic>)],
      renewsAt: DateTime.tryParse('${j['renews_at'] ?? ''}'), balance: (j['balance'] as num?)?.toInt() ?? 0, closed: j['closed'] as String?,
    );
  }

  Future<BuyQuote> buyQuote(int league, int player) async => BuyQuote.fromJson(await _api.get('/leagues/$league/market/buy-quote', query: {'player_id': player}));
  Future<void> buy(int league, int player, {bool compensate = false}) => Intents.run('buy:$league:$player:$compensate',
      (key) => _api.post('/leagues/$league/market/buy', {'player_id': player, 'idempotency_key': key, if (compensate) 'compensate': true}));

  /// My players with their ways to sell (the market's pool view carries them; one line keeps it small).
  Future<Selling> selling(int league) async => Selling.fromJson(await _api.get('/leagues/$league/market', query: {'source': 'pool', 'line': 'gk'}));
  Future<({int floor, int cap, bool ok, int waitHours})> sellQuote(int league, int player, int price) async {
    final j = await _api.get('/leagues/$league/market/quote', query: {'player_id': player, 'price': price});
    return (floor: (j['floor'] as num).toInt(), cap: (j['cap'] as num).toInt(), ok: j['ok'] == true, waitHours: j['wait_hours'] as int? ?? 0);
  }

  Future<void> listForSale(int league, int player, int price) => _api.post('/leagues/$league/transfers/listings', {'player_id': player, 'price': price});
  Future<void> unlist(int league, int player) => _api.delete('/leagues/$league/transfers/listings/$player');
  Future<void> sellNow(int league, int player) =>
      Intents.run('sell:$league:$player', (key) => _api.post('/leagues/$league/market/sell', {'player_id': player, 'idempotency_key': key}));

  Future<Deals> deals(int league) async => Deals.fromJson(await _api.get('/leagues/$league/transfers'));
  Future<void> answer(int league, int offer, String action) => _api.post('/leagues/$league/transfers/offers/$offer/$action');

  /// [Sprint 18 D] Another coach's squad, to ask for his players.
  Future<List<OfferPlayer>> clubPlayers(int league, int club) async => [
        for (final p in ((await _api.get('/leagues/$league/clubs/$club'))['players'] as List? ?? const [])) OfferPlayer.fromJson(p as Map<String, dynamic>),
      ];

  /// A new offer to a coach's club, or (counterOf) an answer with my own terms: `in` his players I want, `out` mine I give.
  Future<void> offer(int league, {int? to, int? counterOf, required int money, required List<int> want, required List<int> give}) {
    return Intents.run('offer:$league:$to:$counterOf:$money:$want:$give', (key) {
      final body = {'money': money, 'in': want, 'out': give, 'idempotency_key': key, 'to_club_id': ?to};
      return counterOf == null ? _api.post('/leagues/$league/transfers/offers', body) : _api.post('/leagues/$league/transfers/offers/$counterOf/counter', body..remove('to_club_id'));
    });
  }

  Future<({List<Loan> loans, int maxRounds, int maxFeeBp})> loans(int league) async {
    final j = await _api.get('/leagues/$league/transfers/loans');
    return (
      loans: [for (final l in (j['loans'] as List? ?? const [])) Loan.fromJson(l as Map<String, dynamic>)],
      maxRounds: j['max_rounds'] as int? ?? 6, maxFeeBp: j['max_fee_bp'] as int? ?? 2000,
    );
  }

  Future<void> askLoan(int league, int player, int rounds, int fee) => _api.post('/leagues/$league/transfers/loans', {'player_id': player, 'rounds': rounds, 'fee': fee});
  Future<void> answerLoan(int league, int loan, bool accept) => _api.post('/leagues/$league/transfers/loans/$loan/answer', {'accept': accept});

  Future<({List<Prospect> prospects, DateTime? renewsAt, int signed, int perSeason})> academy(int league) async {
    final j = await _api.get('/leagues/$league/market/academy');
    return (
      prospects: [for (final p in (j['prospects'] as List? ?? const [])) Prospect.fromJson(p as Map<String, dynamic>)],
      renewsAt: DateTime.tryParse('${j['renews_at'] ?? ''}'), signed: j['signed'] as int? ?? 0, perSeason: j['per_season'] as int? ?? 0,
    );
  }

  Future<void> signProspect(int league, int prospect) => _api.post('/leagues/$league/market/academy', {'master_player_id': prospect});
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) => MarketRepository(ref.watch(apiProvider)));
final marketListProvider = FutureProvider.autoDispose.family((ref, (int, String) k) => ref.read(marketRepositoryProvider).list(k.$1, k.$2));
final sellingProvider = FutureProvider.autoDispose.family<Selling, int>((ref, league) => ref.read(marketRepositoryProvider).selling(league));
final loansProvider = FutureProvider.autoDispose.family((ref, int league) => ref.read(marketRepositoryProvider).loans(league));
final academyProvider = FutureProvider.autoDispose.family((ref, int league) => ref.read(marketRepositoryProvider).academy(league));
final dealsProvider = FutureProvider.autoDispose.family<Deals, int>((ref, league) => ref.read(marketRepositoryProvider).deals(league));
