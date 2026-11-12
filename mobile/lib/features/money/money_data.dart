import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';

/// [Sprint 18 F1] The club's money (`/leagues/{id}/team/finance`, Sprint 23): the balance, the ledger, the sponsors
/// and the ticket price; and the stadium (`/leagues/{id}/stadium`, Sprint 29). The server decides every number.
class Txn {
  const Txn({required this.label, required this.amount, required this.balanceAfter, this.at, this.round});

  factory Txn.of(api.ClubFinanceTransactionsItem t) =>
      Txn(label: t.label, amount: t.amount, balanceAfter: t.balanceAfter, at: DateTime.tryParse(t.createdAt), round: t.round);

  final String label;
  final int amount, balanceAfter;
  final DateTime? at;
  final int? round;
}

class TicketLevel {
  const TicketLevel({required this.level, required this.name, required this.price, required this.attendanceBp, required this.perMatch});

  factory TicketLevel.of(api.TicketLevelsLevelsItem l) =>
      TicketLevel(level: l.level, name: l.name, price: l.price, attendanceBp: l.attendanceBp, perMatch: l.perMatch);

  final String level, name;
  final int price, attendanceBp, perMatch;
}

class Tickets {
  const Tickets({required this.level, required this.levels});

  factory Tickets.of(api.TicketLevels t) => Tickets(level: t.level, levels: [for (final l in t.levels) TicketLevel.of(l)]);

  final String level;
  final List<TicketLevel> levels;
}

class SponsorOffer {
  const SponsorOffer({required this.offer, required this.name, required this.perMatch, required this.perWin});

  factory SponsorOffer.of(api.ClubFinanceSponsorsItemOffersItem o) =>
      SponsorOffer(offer: o.offer, name: o.name, perMatch: o.perMatch, perWin: o.perWin);

  final String offer, name;
  final int perMatch, perWin;
}

class Sponsor {
  const Sponsor({required this.sector, required this.name, this.chosen, required this.offers});

  factory Sponsor.of(api.ClubFinanceSponsorsItem s) =>
      Sponsor(sector: s.sector, name: s.name, chosen: s.chosen, offers: [for (final o in s.offers) SponsorOffer.of(o)]);

  final String sector, name;
  final String? chosen;
  final List<SponsorOffer> offers;
}

class Finance {
  const Finance({
    required this.balance,
    required this.canSpend,
    required this.debtRounds,
    required this.debtLimit,
    required this.wagesPerRound,
    required this.income,
    required this.expenses,
    required this.totals,
    required this.transactions,
    required this.tickets,
    required this.sponsors,
  });

  /// [Sprint 59 F1] The club's money (`ClubFinance`), read through its generated model.
  factory Finance.fromJson(Object? json) {
    final f = api.ClubFinance.fromJson(json);
    return Finance(
      balance: f.balance,
      canSpend: f.canSpend,
      debtRounds: f.debtRounds,
      debtLimit: f.debtLimit,
      wagesPerRound: f.wagesPerRound,
      income: f.seasonIncome,
      expenses: f.seasonExpenses,
      totals: [for (final t in f.seasonTotals) (label: t.label, total: t.total)],
      transactions: [for (final t in f.transactions) Txn.of(t)],
      tickets: Tickets.of(f.tickets),
      sponsors: [for (final s in f.sponsors) Sponsor.of(s)],
    );
  }

  final int balance, debtRounds, debtLimit, wagesPerRound, income, expenses;
  final bool canSpend;
  final List<({String label, int total})> totals;
  final List<Txn> transactions;
  final Tickets tickets;
  final List<Sponsor> sponsors;
}

class StadiumSection {
  const StadiumSection({
    required this.section,
    required this.stage,
    required this.parts,
    required this.done,
    required this.effects,
    this.next,
  });

  factory StadiumSection.of(api.StadiumViewSectionsItem s) => StadiumSection(
    section: s.section,
    stage: s.stage,
    parts: s.parts,
    done: s.done,
    effects: s.effects,
    next: s.next == null ? null : (stage: s.next!.stage, part: s.next!.part_, cost: s.next!.cost),
  );

  final String section;
  final int stage, parts, done;
  final List<int> effects;
  final ({int stage, int part, int cost})? next;
}

class StadiumView {
  const StadiumView({
    required this.balance,
    required this.partMinutes,
    required this.partsTotal,
    required this.partsDone,
    required this.capacity,
    required this.homeBp,
    required this.sections,
    this.building,
    this.now,
  });

  /// [Sprint 59 F1] The stadium (`StadiumView`), read through its generated model.
  factory StadiumView.fromJson(Object? json) {
    final v = api.StadiumView.fromJson(json);
    final b = v.building;
    return StadiumView(
      balance: v.balance,
      partMinutes: v.partMinutes,
      partsTotal: v.partsTotal,
      partsDone: v.facts.partsDone,
      capacity: v.facts.capacity,
      homeBp: v.facts.homeBp,
      sections: [for (final s in v.sections) StadiumSection.of(s)],
      building: b == null
          ? null
          : (section: b.section, stage: b.stage, part: b.part_, endsAt: DateTime.parse(b.endsAt), finishCoins: b.finishCoins ?? 0),
      now: DateTime.tryParse(v.now),
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
  Future<void> signSponsor(int league, String sector, String offer) =>
      _api.post('/leagues/$league/team/sponsors', {'sector': sector, 'offer': offer});
  Future<void> setTickets(int league, String level) => _api.put('/leagues/$league/team/tickets', {'level': level});

  Future<StadiumView> stadium(int league) async => StadiumView.fromJson(await _api.get('/leagues/$league/stadium'));
  Future<StadiumView> build(int league, String section) async => StadiumView.fromJson(
    await Intents.run(
      'stadium:$league:$section',
      (key) => _api.post('/leagues/$league/stadium', {'section': section, 'idempotency_key': key}),
    ),
  );
  Future<StadiumView> finishNow(int league) async => StadiumView.fromJson(await _api.post('/leagues/$league/stadium/finish'));
}

final moneyRepositoryProvider = Provider<MoneyRepository>((ref) => MoneyRepository(ref.watch(apiProvider)));
final financeProvider = FutureProvider.autoDispose.family<Finance, int>((ref, league) => ref.read(moneyRepositoryProvider).finance(league));
final stadiumProvider = FutureProvider.autoDispose.family<StadiumView, int>(
  (ref, league) => ref.read(moneyRepositoryProvider).stadium(league),
);
