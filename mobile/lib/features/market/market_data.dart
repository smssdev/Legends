import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';
import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';

// [Sprint 59 F1] The buy quote is the generated model (docs/api/openapi.yaml → lib/api/gen/models.g.dart).
import '../../api/gen/models.g.dart'
    show BuyQuote, Market, MarketMineItem, TradePlayer, TransferList, TransferListPlayer, TransferOffer, Transfers;
export '../../api/gen/models.g.dart' show BuyQuote, BuyQuoteCompensate;

/// [Sprint 18 F1] The market (`/leagues/{id}/market`, UP11) and the deals between coaches (`/leagues/{id}/transfers`,
/// Sprint 25): the server sets every price, floor, cap, wait and fee; the app shows them and sends the coach's choice.
class MarketPlayer {
  const MarketPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.line,
    required this.age,
    required this.overall,
    this.potential,
    required this.value,
    required this.price,
    this.wasPrice,
    this.nationality,
    this.sellerKind,
    this.sellerClub,
    this.sellerCoach,
    this.fits = false,
    this.star = false,
    this.attributes = const {},
  });

  /// [Sprint 59 F1] A player of the transfer list, from its generated model (a field renamed in the contract fails
  /// `flutter analyze` here).
  factory MarketPlayer.of(TransferListPlayer p) => MarketPlayer(
    id: p.id,
    name: p.name,
    position: p.position,
    line: p.line,
    age: p.age,
    overall: p.overall,
    potential: p.potential,
    value: p.value,
    price: p.price,
    wasPrice: p.wasPrice,
    nationality: p.nationality,
    sellerKind: p.seller.kind,
    sellerClub: p.seller.club,
    sellerCoach: p.seller.coach,
    fits: p.fits,
    star: p.star,
    attributes: {for (final e in p.attributes.entries) e.key: e.value ?? 0},
  );

  final int id, age, overall, value, price;
  final int? potential, wasPrice;
  final String name, position, line;
  final String? nationality, sellerKind, sellerClub, sellerCoach;
  final bool fits, star;
  final Map<String, int> attributes;
}

/// One of my players and the two ways to sell him: listed (up to his cap, waiting for a buyer) or now (a fee).
class MyPlayer {
  const MyPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.line,
    required this.overall,
    required this.value,
    required this.cost,
    required this.floor,
    required this.cap,
    required this.quickPays,
    required this.quickFee,
    required this.waitValue,
    required this.waitCap,
    this.listedPrice,
    this.sellsAt,
  });

  /// [Sprint 59 F1] From the generated model (`Market.mine`).
  factory MyPlayer.of(MarketMineItem p) => MyPlayer(
    id: p.id,
    name: p.name,
    position: p.position,
    line: p.line,
    overall: p.overall,
    value: p.value,
    cost: p.cost ?? 0,
    floor: p.floor,
    cap: p.cap,
    quickPays: p.quick.pays,
    quickFee: (currency: p.quick.fee.currency, amount: p.quick.fee.amount),
    waitValue: p.waitHours.value,
    waitCap: p.waitHours.cap,
    listedPrice: p.listed?.price,
    sellsAt: DateTime.tryParse(p.listed?.sellsAt ?? ''),
  );

  final int id, overall, value, cost, floor, cap, quickPays, waitValue, waitCap;
  final String name, position, line;
  final ({String currency, int amount}) quickFee;
  final int? listedPrice;
  final DateTime? sellsAt;

  bool get listed => listedPrice != null;
}

class Selling {
  const Selling({required this.mine, required this.maxListings, required this.listed, this.closed});

  /// [Sprint 59 F1] The market's pool answer (`Market`), read through its generated model.
  factory Selling.fromJson(Object? json) {
    final m = Market.fromJson(json);
    return Selling(
      mine: [for (final p in m.mine) MyPlayer.of(p)],
      maxListings: m.selling?.maxListings ?? 4,
      listed: m.selling?.listed ?? 0,
      closed: m.closed,
    );
  }

  final List<MyPlayer> mine;
  final int maxListings, listed;
  final String? closed;
}

class OfferPlayer {
  const OfferPlayer({required this.id, required this.name, required this.position, required this.overall, required this.value});

  /// [Sprint 59 F1] From the generated model (an offer's or a listing's player).
  factory OfferPlayer.of(TradePlayer p) => OfferPlayer(id: p.id, name: p.name, position: p.position, overall: p.overall, value: p.value);

  /// [Sprint 59 F1] A club's player (`LeaguePlayer`, GET /leagues/{league}/clubs/{club}).
  factory OfferPlayer.ofClub(api.LeaguePlayer p) =>
      OfferPlayer(id: p.id ?? 0, name: p.name ?? '', position: p.position ?? '', overall: p.overall ?? 0, value: p.value ?? 0);

  final int id, overall, value;
  final String name, position;
}

class Offer {
  const Offer({
    required this.id,
    required this.status,
    required this.money,
    required this.from,
    required this.to,
    required this.incoming,
    required this.players,
    required this.give,
    this.expiresAt,
    this.fromId = 0,
    this.toId = 0,
  });

  /// [Sprint 59 F1] From the generated model.
  factory Offer.of(TransferOffer o) => Offer(
    id: o.id,
    status: o.status,
    money: o.money,
    from: o.from.name,
    to: o.to.name,
    incoming: o.incoming,
    fromId: o.from.id,
    toId: o.to.id,
    players: [for (final p in o.in_) OfferPlayer.of(p)],
    give: [for (final p in o.out) OfferPlayer.of(p)],
    expiresAt: DateTime.tryParse(o.expiresAt),
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
  const Deals({
    required this.offers,
    required this.listings,
    this.closed,
    this.clubs = const [],
    this.fairMinBp = 5000,
    this.fairMaxBp = 20000,
  });

  /// [Sprint 59 F1] The market between coaches (`Transfers`), read through its generated model.
  factory Deals.fromJson(Object? json) {
    final t = Transfers.fromJson(json);
    return Deals(
      offers: [for (final o in t.offers) Offer.of(o)],
      listings: [for (final l in t.listings) (player: OfferPlayer.of(l.player), price: l.price, club: l.club.name, mine: l.mine)],
      closed: t.closed,
      clubs: [for (final c in t.clubs) (id: c.id, name: c.name)],
      fairMinBp: t.fair.minBp,
      fairMaxBp: t.fair.maxBp,
    );
  }

  /// The coaches' clubs an offer can go to, and the fair range of a deal (its money and players against the values).
  final List<({int id, String name})> clubs;
  final int fairMinBp, fairMaxBp;
  final List<Offer> offers;
  final List<({OfferPlayer player, int price, String club, bool mine})> listings;
  final String? closed;
}

/// [X61 E2] A loan between coaches: asked, running or done; `mine` when the player is mine.
class Loan {
  const Loan({
    required this.id,
    required this.status,
    required this.mine,
    required this.player,
    required this.owner,
    required this.borrower,
    required this.rounds,
    required this.fee,
    this.untilRound,
  });

  /// [Sprint 59 F1] From the generated model (`Loans`).
  factory Loan.fromJson(Object? json) {
    final l = api.LoansLoansItem.fromJson(json);
    return Loan(
      id: l.id,
      status: l.status,
      mine: l.mine,
      player: l.player.name,
      owner: l.owner,
      borrower: l.borrower,
      rounds: l.rounds,
      fee: l.fee,
      untilRound: l.untilRound,
    );
  }

  final int id, rounds, fee;
  final int? untilRound;
  final String status, player, owner, borrower;
  final bool mine;

  bool get pending => status == 'pending';
}

/// [X61 E3] This period's academy prospects: the potential as a range until signed.
class Prospect {
  const Prospect({
    required this.id,
    required this.name,
    required this.position,
    required this.line,
    required this.age,
    required this.overall,
    required this.potentialFrom,
    required this.potentialTo,
    required this.price,
    this.nationality,
  });

  /// [Sprint 59 F1] From the generated model (`Academy`).
  factory Prospect.fromJson(Object? json) {
    final p = api.AcademyProspectsItem.fromJson(json);
    return Prospect(
      id: p.id,
      name: p.name,
      position: p.position,
      line: p.line,
      age: p.age,
      overall: p.overall,
      potentialFrom: p.potentialFrom,
      potentialTo: p.potentialTo,
      price: p.price,
      nationality: p.nationality,
    );
  }

  final int id, age, overall, potentialFrom, potentialTo, price;
  final String name, position, line;
  final String? nationality;
}

class MarketRepository {
  MarketRepository(this._api);

  final ApiClient _api;

  Future<({List<MarketPlayer> players, DateTime? renewsAt, int balance, String? closed})> list(int league, String line) async {
    final t = TransferList.fromJson(await _api.get('/leagues/$league/market', query: {'line': line}));
    return (
      players: [for (final p in t.players) MarketPlayer.of(p)],
      renewsAt: DateTime.tryParse(t.renewsAt ?? ''),
      balance: t.balance,
      closed: t.closed,
    );
  }

  Future<BuyQuote> buyQuote(int league, int player) async =>
      BuyQuote.fromJson(await _api.get('/leagues/$league/market/buy-quote', query: {'player_id': player}));

  /// [Sprint 59 F5] With the key BuyController holds for this purchase (the same on a retry).
  Future<void> buy(int league, int player, {bool compensate = false, required String key}) =>
      _api.post('/leagues/$league/market/buy', {'player_id': player, 'idempotency_key': key, if (compensate) 'compensate': true});

  /// My players with their ways to sell (the market's pool view carries them; one line keeps it small).
  Future<Selling> selling(int league) async =>
      Selling.fromJson(await _api.get('/leagues/$league/market', query: {'source': 'pool', 'line': 'gk'}));
  Future<({int floor, int cap, bool ok, int waitHours})> sellQuote(int league, int player, int price) async {
    final q = api.LeaguesMarketQuoteAnswer.fromJson(
      await _api.get('/leagues/$league/market/quote', query: {'player_id': player, 'price': price}),
    );
    return (floor: q.floor, cap: q.cap, ok: q.ok, waitHours: q.waitHours);
  }

  Future<void> listForSale(int league, int player, int price) =>
      _api.post('/leagues/$league/transfers/listings', {'player_id': player, 'price': price});
  Future<void> unlist(int league, int player) => _api.delete('/leagues/$league/transfers/listings/$player');
  Future<void> sellNow(int league, int player) => Intents.run(
    'sell:$league:$player',
    (key) => _api.post('/leagues/$league/market/sell', {'player_id': player, 'idempotency_key': key}),
  );

  Future<Deals> deals(int league) async => Deals.fromJson(await _api.get('/leagues/$league/transfers'));
  Future<void> answer(int league, int offer, String action) => _api.post('/leagues/$league/transfers/offers/$offer/$action');

  /// [Sprint 18 D] Another coach's squad, to ask for his players.
  Future<List<OfferPlayer>> clubPlayers(int league, int club) async => [
    for (final p in api.LeaguesClubsByClubAnswer.fromJson(await _api.get('/leagues/$league/clubs/$club')).players) OfferPlayer.ofClub(p),
  ];

  /// A new offer to a coach's club, or (counterOf) an answer with my own terms: `in` his players I want, `out` mine I give.
  Future<void> offer(int league, {int? to, int? counterOf, required int money, required List<int> want, required List<int> give}) {
    return Intents.run('offer:$league:$to:$counterOf:$money:$want:$give', (key) {
      final body = {'money': money, 'in': want, 'out': give, 'idempotency_key': key, 'to_club_id': ?to};
      return counterOf == null
          ? _api.post('/leagues/$league/transfers/offers', body)
          : _api.post('/leagues/$league/transfers/offers/$counterOf/counter', body..remove('to_club_id'));
    });
  }

  Future<({List<Loan> loans, int maxRounds, int maxFeeBp})> loans(int league) async {
    final j = await _api.get('/leagues/$league/transfers/loans');
    final v = api.Loans.fromJson(j);
    return (loans: JsonReader(j, 'Loans').list('loans', Loan.fromJson), maxRounds: v.maxRounds, maxFeeBp: v.maxFeeBp);
  }

  Future<void> askLoan(int league, int player, int rounds, int fee) =>
      _api.post('/leagues/$league/transfers/loans', {'player_id': player, 'rounds': rounds, 'fee': fee});
  Future<void> answerLoan(int league, int loan, bool accept) =>
      _api.post('/leagues/$league/transfers/loans/$loan/answer', {'accept': accept});

  Future<({List<Prospect> prospects, DateTime? renewsAt, int signed, int perSeason})> academy(int league) async {
    final j = await _api.get('/leagues/$league/market/academy');
    final a = api.Academy.fromJson(j);
    return (
      prospects: JsonReader(j, 'Academy').list('prospects', Prospect.fromJson),
      renewsAt: DateTime.tryParse(a.renewsAt),
      signed: a.signed,
      perSeason: a.perSeason,
    );
  }

  Future<void> signProspect(int league, int prospect) => _api.post('/leagues/$league/market/academy', {'master_player_id': prospect});
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) => MarketRepository(ref.watch(apiProvider)));
final marketListProvider = FutureProvider.autoDispose.family((ref, (int, String) k) => ref.read(marketRepositoryProvider).list(k.$1, k.$2));
final sellingProvider = FutureProvider.autoDispose.family<Selling, int>(
  (ref, league) => ref.read(marketRepositoryProvider).selling(league),
);
final loansProvider = FutureProvider.autoDispose.family((ref, int league) => ref.read(marketRepositoryProvider).loans(league));
final academyProvider = FutureProvider.autoDispose.family((ref, int league) => ref.read(marketRepositoryProvider).academy(league));
final dealsProvider = FutureProvider.autoDispose.family<Deals, int>((ref, league) => ref.read(marketRepositoryProvider).deals(league));
