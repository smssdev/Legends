import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';

/// [Sprint 18 F1] The club's money (`/leagues/{id}/team/finance`, Sprint 23): the balance, the ledger, the sponsors
/// and the ticket price; and the stadium (`/leagues/{id}/stadium`, Sprint 29). The server decides every number.
class Txn {
  const Txn({required this.label, required this.amount, required this.balanceAfter, this.at, this.round});

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        label: '${j['label'] ?? j['type']}', amount: (j['amount'] as num).toInt(), balanceAfter: (j['balance_after'] as num?)?.toInt() ?? 0,
        at: DateTime.tryParse('${j['created_at'] ?? ''}'), round: j['round'] as int?,
      );

  final String label;
  final int amount, balanceAfter;
  final DateTime? at;
  final int? round;
}

class TicketLevel {
  const TicketLevel({required this.level, required this.name, required this.price, required this.attendanceBp, required this.perMatch});

  factory TicketLevel.fromJson(Map<String, dynamic> j) => TicketLevel(
        level: '${j['level']}', name: '${j['name']}', price: (j['price'] as num?)?.toInt() ?? 0,
        attendanceBp: (j['attendance_bp'] as num?)?.toInt() ?? 10000, perMatch: (j['per_match'] as num?)?.toInt() ?? 0,
      );

  final String level, name;
  final int price, attendanceBp, perMatch;
}

class Tickets {
  const Tickets({required this.level, required this.levels});

  factory Tickets.fromJson(Map<String, dynamic>? j) => Tickets(
        level: '${j?['level'] ?? 'normal'}',
        levels: [for (final l in (j?['levels'] as List<dynamic>? ?? const [])) TicketLevel.fromJson(l as Map<String, dynamic>)],
      );

  final String level;
  final List<TicketLevel> levels;
}

class SponsorOffer {
  const SponsorOffer({required this.offer, required this.name, required this.perMatch, required this.perWin});

  factory SponsorOffer.fromJson(Map<String, dynamic> j) =>
      SponsorOffer(offer: '${j['offer']}', name: '${j['name']}', perMatch: (j['per_match'] as num?)?.toInt() ?? 0, perWin: (j['per_win'] as num?)?.toInt() ?? 0);

  final String offer, name;
  final int perMatch, perWin;
}

class Sponsor {
  const Sponsor({required this.sector, required this.name, this.chosen, required this.offers});

  factory Sponsor.fromJson(Map<String, dynamic> j) {
    final chosen = j['chosen'];
    return Sponsor(
      sector: '${j['sector']}', name: '${j['name']}',
      chosen: chosen is Map<dynamic, dynamic> ? '${chosen['offer']}' : chosen as String?,
      offers: [for (final o in (j['offers'] as List<dynamic>? ?? const [])) SponsorOffer.fromJson(o as Map<String, dynamic>)],
    );
  }

  final String sector, name;
  final String? chosen;
  final List<SponsorOffer> offers;
}

class Finance {
  const Finance({required this.balance, required this.canSpend, required this.debtRounds, required this.debtLimit, required this.wagesPerRound,
      required this.income, required this.expenses, required this.totals, required this.transactions, required this.tickets, required this.sponsors});

  factory Finance.fromJson(Map<String, dynamic> j) => Finance(
        balance: (j['balance'] as num).toInt(), canSpend: j['can_spend'] != false,
        debtRounds: j['debt_rounds'] as int? ?? 0, debtLimit: j['debt_limit'] as int? ?? 3,
        wagesPerRound: (j['wages_per_round'] as num?)?.toInt() ?? 0,
        income: (j['season_income'] as num?)?.toInt() ?? 0, expenses: (j['season_expenses'] as num?)?.toInt() ?? 0,
        totals: [for (final t in (j['season_totals'] as List<dynamic>? ?? const [])) (label: '${(t as Map<dynamic, dynamic>)['label']}', total: (t['total'] as num).toInt())],
        transactions: [for (final t in (j['transactions'] as List<dynamic>? ?? const [])) Txn.fromJson(t as Map<String, dynamic>)],
        tickets: Tickets.fromJson(j['tickets'] as Map<String, dynamic>?),
        sponsors: [for (final s in (j['sponsors'] as List<dynamic>? ?? const [])) Sponsor.fromJson(s as Map<String, dynamic>)],
      );

  final int balance, debtRounds, debtLimit, wagesPerRound, income, expenses;
  final bool canSpend;
  final List<({String label, int total})> totals;
  final List<Txn> transactions;
  final Tickets tickets;
  final List<Sponsor> sponsors;
}

class StadiumSection {
  const StadiumSection({required this.section, required this.stage, required this.parts, required this.done, required this.effects, this.next});

  factory StadiumSection.fromJson(Map<String, dynamic> j) {
    final n = j['next'] as Map<String, dynamic>?;
    return StadiumSection(
      section: '${j['section']}', stage: j['stage'] as int? ?? 0, parts: j['parts'] as int? ?? 0, done: j['done'] as int? ?? 0,
      effects: [for (final e in (j['effects'] as List<dynamic>? ?? const [])) (e as num).toInt()],
      next: n == null ? null : (stage: n['stage'] as int, part: n['part'] as int, cost: (n['cost'] as num).toInt()),
    );
  }

  final String section;
  final int stage, parts, done;
  final List<int> effects;
  final ({int stage, int part, int cost})? next;
}

class StadiumView {
  const StadiumView({required this.balance, required this.partMinutes, required this.partsTotal, required this.partsDone, required this.capacity,
      required this.homeBp, required this.sections, this.building, this.now});

  factory StadiumView.fromJson(Map<String, dynamic> j) {
    final facts = j['facts'] as Map<String, dynamic>? ?? const {};
    final b = j['building'] as Map<String, dynamic>?;
    return StadiumView(
      balance: (j['balance'] as num?)?.toInt() ?? 0, partMinutes: j['part_minutes'] as int? ?? 0, partsTotal: j['parts_total'] as int? ?? 45,
      partsDone: facts['parts_done'] as int? ?? 0, capacity: facts['capacity'] as int? ?? 0, homeBp: facts['home_bp'] as int? ?? 0,
      sections: [for (final s in (j['sections'] as List<dynamic>? ?? const [])) StadiumSection.fromJson(s as Map<String, dynamic>)],
      building: b == null ? null : (section: '${b['section']}', stage: b['stage'] as int, part: b['part'] as int, endsAt: DateTime.parse('${b['ends_at']}'), finishCoins: b['finish_coins'] as int? ?? 0),
      now: DateTime.tryParse('${j['now'] ?? ''}'),
    );
  }

  final int balance, partMinutes, partsTotal, partsDone, capacity, homeBp;
  final List<StadiumSection> sections;
  final ({String section, int stage, int part, DateTime endsAt, int finishCoins})? building;
  final DateTime? now;
}

class MoneyRepository {
  MoneyRepository(this._api);

  final ApiClient _api;

  Future<Finance> finance(int league) async => Finance.fromJson(await _api.get('/leagues/$league/team/finance'));
  Future<void> signSponsor(int league, String sector, String offer) => _api.post('/leagues/$league/team/sponsors', {'sector': sector, 'offer': offer});
  Future<void> setTickets(int league, String level) => _api.put('/leagues/$league/team/tickets', {'level': level});

  Future<StadiumView> stadium(int league) async => StadiumView.fromJson(await _api.get('/leagues/$league/stadium'));
  Future<StadiumView> build(int league, String section) async => StadiumView.fromJson(await Intents.run(
      'stadium:$league:$section', (key) => _api.post('/leagues/$league/stadium', {'section': section, 'idempotency_key': key})));
  Future<StadiumView> finishNow(int league) async => StadiumView.fromJson(await _api.post('/leagues/$league/stadium/finish'));
}

final moneyRepositoryProvider = Provider<MoneyRepository>((ref) => MoneyRepository(ref.watch(apiProvider)));
final financeProvider = FutureProvider.autoDispose.family<Finance, int>((ref, league) => ref.read(moneyRepositoryProvider).finance(league));
final stadiumProvider = FutureProvider.autoDispose.family<StadiumView, int>((ref, league) => ref.read(moneyRepositoryProvider).stadium(league));
