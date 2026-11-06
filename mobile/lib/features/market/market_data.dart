import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

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
      required this.players, required this.give, this.expiresAt});

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: j['id'] as int, status: '${j['status']}', money: (j['money'] as num?)?.toInt() ?? 0,
        from: '${(j['from'] as Map?)?['name'] ?? ''}', to: '${(j['to'] as Map?)?['name'] ?? ''}', incoming: j['incoming'] == true,
        players: [for (final p in (j['in'] as List? ?? const [])) OfferPlayer.fromJson(p as Map<String, dynamic>)],
        give: [for (final p in (j['out'] as List? ?? const [])) OfferPlayer.fromJson(p as Map<String, dynamic>)],
        expiresAt: DateTime.tryParse('${j['expires_at'] ?? ''}'),
      );

  final int id, money;
  final String status, from, to;
  final bool incoming;

  /// From the offering club's side: the players it asks for (`in`) and those it gives (`out`).
  final List<OfferPlayer> players, give;
  final DateTime? expiresAt;

  bool get pending => status == 'pending';
}

class Deals {
  const Deals({required this.offers, required this.listings, this.closed});

  factory Deals.fromJson(Map<String, dynamic> j) => Deals(
        offers: [for (final o in (j['offers'] as List? ?? const [])) Offer.fromJson(o as Map<String, dynamic>)],
        listings: [
          for (final l in (j['listings'] as List? ?? const []))
            (player: OfferPlayer.fromJson((l as Map)['player'] as Map<String, dynamic>), price: (l['price'] as num).toInt(), club: '${(l['club'] as Map?)?['name'] ?? ''}', mine: l['mine'] == true),
        ],
        closed: j['closed'] as String?,
      );

  final List<Offer> offers;
  final List<({OfferPlayer player, int price, String club, bool mine})> listings;
  final String? closed;
}

class MarketRepository {
  MarketRepository(this._api);

  final ApiClient _api;

  String _key() => 'app-${DateTime.now().microsecondsSinceEpoch}';

  Future<({List<MarketPlayer> players, DateTime? renewsAt, int balance, String? closed})> list(int league, String line) async {
    final j = await _api.get('/leagues/$league/market', query: {'line': line});
    return (
      players: [for (final p in (j['players'] as List? ?? const [])) MarketPlayer.fromJson(p as Map<String, dynamic>)],
      renewsAt: DateTime.tryParse('${j['renews_at'] ?? ''}'), balance: (j['balance'] as num?)?.toInt() ?? 0, closed: j['closed'] as String?,
    );
  }

  Future<BuyQuote> buyQuote(int league, int player) async => BuyQuote.fromJson(await _api.get('/leagues/$league/market/buy-quote', query: {'player_id': player}));
  Future<void> buy(int league, int player, {bool compensate = false}) =>
      _api.post('/leagues/$league/market/buy', {'player_id': player, 'idempotency_key': _key(), if (compensate) 'compensate': true});

  /// My players with their ways to sell (the market's pool view carries them; one line keeps it small).
  Future<Selling> selling(int league) async => Selling.fromJson(await _api.get('/leagues/$league/market', query: {'source': 'pool', 'line': 'gk'}));
  Future<({int floor, int cap, bool ok, int waitHours})> sellQuote(int league, int player, int price) async {
    final j = await _api.get('/leagues/$league/market/quote', query: {'player_id': player, 'price': price});
    return (floor: (j['floor'] as num).toInt(), cap: (j['cap'] as num).toInt(), ok: j['ok'] == true, waitHours: j['wait_hours'] as int? ?? 0);
  }

  Future<void> listForSale(int league, int player, int price) => _api.post('/leagues/$league/transfers/listings', {'player_id': player, 'price': price});
  Future<void> unlist(int league, int player) => _api.delete('/leagues/$league/transfers/listings/$player');
  Future<void> sellNow(int league, int player) => _api.post('/leagues/$league/market/sell', {'player_id': player, 'idempotency_key': _key()});

  Future<Deals> deals(int league) async => Deals.fromJson(await _api.get('/leagues/$league/transfers'));
  Future<void> answer(int league, int offer, String action) => _api.post('/leagues/$league/transfers/offers/$offer/$action');
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) => MarketRepository(ref.watch(apiProvider)));
final marketListProvider = FutureProvider.autoDispose.family((ref, (int, String) k) => ref.read(marketRepositoryProvider).list(k.$1, k.$2));
final sellingProvider = FutureProvider.autoDispose.family<Selling, int>((ref, league) => ref.read(marketRepositoryProvider).selling(league));
final dealsProvider = FutureProvider.autoDispose.family<Deals, int>((ref, league) => ref.read(marketRepositoryProvider).deals(league));
