import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/api/gen/models.g.dart' show TransferList;
import 'package:glm/core/settings.dart';
import 'package:glm/features/market/market_data.dart';
import 'package:glm/features/market/market_screen.dart';
import 'package:glm/features/market/offer_screen.dart';
import 'package:glm/features/market/scout_screen.dart';
import 'package:glm/features/market/sell_sheet.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glm/api/gen/models.g.dart' as api;

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Real replies from a local server (the offers written in the server's shape), and what the screens send.
class FakeMarket implements MarketRepository {
  final List<String> sent = [];
  final List<String> asked = [];

  @override
  Future<({List<MarketPlayer> players, DateTime? renewsAt, int balance, String? closed})> list(
    int league,
    String line, {
    String q = '',
    int? maxPrice,
  }) async {
    asked.add('$line q:$q max:$maxPrice');
    // [Sprint 59 F1] The captured answer read through the generated model: the fixture checks the contract too.
    final t = TransferList.fromJson(json('market'));
    expect(t.players, hasLength((json('market')['players'] as List<dynamic>).length), reason: 'every player reads');
    return (
      players: [for (final p in t.players) MarketPlayer.of(p)],
      renewsAt: DateTime.tryParse(t.renewsAt ?? ''),
      balance: 0,
      closed: null,
    );
  }

  @override
  Future<BuyQuote> buyQuote(int league, int player) async =>
      BuyQuote.fromJson({'price': 530000, 'cash': 2971870, 'doc_coins': 1, 'short': 0, 'compensate': null, 'can': true, 'why': null});
  @override
  Future<void> buy(int league, int player, {bool compensate = false, required String key}) async => sent.add('buy $player');
  @override
  Future<Selling> selling(int league) async => Selling.fromJson(json('market_pool'));
  @override
  Future<({int floor, int cap, bool ok, int waitHours})> sellQuote(int league, int player, int price) async =>
      (floor: 1, cap: 2, ok: true, waitHours: 6);
  @override
  Future<void> listForSale(int league, int player, int price) async => sent.add('list $player $price');
  @override
  Future<void> unlist(int league, int player) async => sent.add('unlist $player');
  @override
  Future<void> sellNow(int league, int player) async => sent.add('sell $player');
  @override
  Future<Deals> deals(int league) async => Deals.fromJson(json('offers'));
  @override
  Future<void> answer(int league, int offer, String action) async => sent.add('$action $offer');
  @override
  Future<List<OfferPlayer>> clubPlayers(int league, int club) async => [
    for (final p in json('club_142')['players'] as List<dynamic>) OfferPlayer.ofClub(api.LeaguePlayer.fromJson(p)),
  ];
  @override
  Future<void> offer(int league, {int? to, int? counterOf, required int money, required List<int> want, required List<int> give}) async =>
      sent.add('offer to:$to counter:$counterOf money:$money want:$want give:$give');
  @override
  Future<({List<Loan> loans, int maxRounds, int maxFeeBp})> loans(int league) async => (
    loans: [
      Loan.fromJson({
        'id': 4,
        'status': 'pending',
        'mine': true,
        'player': {'id': 5625, 'name': 'Florian Wirtz', 'position': 'CAM'},
        'owner': 'Liverpool',
        'borrower': 'Arsenal',
        'rounds': 3,
        'fee': 500000,
        'until_round': null,
      }),
    ],
    maxRounds: 6,
    maxFeeBp: 2000,
  );
  @override
  Future<void> askLoan(int league, int player, int rounds, int fee) async => sent.add('loan $player $rounds $fee');
  @override
  Future<void> answerLoan(int league, int loan, bool accept) async => sent.add('loan $loan $accept');
  @override
  Future<({List<Prospect> prospects, DateTime? renewsAt, int signed, int perSeason})> academy(int league) async {
    final j = json('academy');
    return (prospects: [for (final p in j['prospects'] as List<dynamic>) Prospect.fromJson(p)], renewsAt: null, signed: 0, perSeason: 2);
  }

  @override
  Future<void> signProspect(int league, int prospect) async => sent.add('academy $prospect');
}

class FakeScout implements ScoutRepository {
  @override
  Future<ScoutView> show(int league) async => ScoutView.fromJson(json('scout_done'));
  @override
  Future<ScoutView> ask(int league, Map<String, Object> criteria) async => ScoutView.fromJson(json('scout_done'));
  @override
  Future<ScoutView> finishNow(int league) async => ScoutView.fromJson(json('scout_done'));
}

Future<void> pump(WidgetTester t, Widget screen, FakeMarket market) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(360 * 3, 3200 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        marketRepositoryProvider.overrideWithValue(market),
        scoutRepositoryProvider.overrideWithValue(FakeScout()),
      ],
      child: MaterialApp(
        theme: glmTheme(day: false),
        locale: const Locale('ar'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  test('the market, my players for sale and the offers from the API', () {
    final s = Selling.fromJson(json('market_pool'));
    expect(s.mine, isNotEmpty);
    // [Sprint 59 F1] Every one of my players reads through the generated model.
    expect(s.mine, hasLength((json('market_pool')['mine'] as List<dynamic>).length));
    expect(s.mine.first.cap, greaterThan(s.mine.first.floor));
    expect(s.mine.first.quickFee.currency, 'coins');
    final d = Deals.fromJson(json('offers'));
    // [Sprint 59 F1] Every offer and listing reads through the generated model.
    expect(d.offers, hasLength((json('offers')['offers'] as List<dynamic>).length));
    expect(d.listings, hasLength((json('offers')['listings'] as List<dynamic>).length));
    expect(d.offers.first.incoming, isTrue);
    expect(d.offers.first.players.single.name, 'Florian Wirtz');
  });

  testWidgets('buy: a player from the list at the server\'s price', (t) async {
    final m = FakeMarket();
    await pump(t, const MarketScreen(leagueId: 8), m);
    expect(find.text('Gianluigi Donnarumma'), findsOneWidget);
    await t.tap(find.text('Gianluigi Donnarumma'));
    await t.pumpAndSettle();
    expect(find.text('رسوم التسجيل 1 كوينز'), findsOneWidget);
    await t.tap(find.textContaining('اشترِه بـ'));
    await t.pumpAndSettle();
    expect(m.sent, ['buy 5676']);
    expect(find.text('صار في فريقك'), findsOneWidget);
  });

  testWidgets('the filters drawer: a name and a highest price asked of the server, a chip clears one', (t) async {
    final m = FakeMarket();
    await t.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await pump(t, const MarketScreen(leagueId: 8), m);
    await t.tap(find.text('الفلاتر'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, 'Don');
    await t.tap(find.byType(ChoiceChip).at(2));
    await t.tap(find.text('طبّق'));
    await t.pumpAndSettle();
    expect(m.asked.last, 'gk q:Don max:5000000');
    expect(find.byType(InputChip), findsNWidgets(2));
    await t.tap(find.descendant(of: find.byType(InputChip).first, matching: find.byType(Icon)).last);
    await t.pumpAndSettle();
    expect(m.asked.last, 'gk q: max:5000000');
  });

  testWidgets('sell: list a player at his value, and the offers answered', (t) async {
    final m = FakeMarket();
    await pump(t, const MarketScreen(leagueId: 8), m);
    await t.tap(find.text('بيع'));
    await t.pumpAndSettle();
    await t.tap(find.text('Florian Wirtz'));
    await t.pumpAndSettle();
    expect(find.textContaining('بيع فوري'), findsOneWidget);
    await t.tap(find.text('اعرضه للبيع'));
    await t.pumpAndSettle();
    expect(m.sent, ['list 5625 17800000']);

    await t.tap(find.text('العروض'));
    await t.pumpAndSettle();
    expect(find.text('عرض من Arsenal'), findsOneWidget);
    expect(find.text('مرفوض'), findsOneWidget);
    await t.tap(find.text('اقبل').first);
    await t.pumpAndSettle();
    expect(m.sent.last, 'accept 31');
  });

  testWidgets('[X114] a player whose line is at the squad\'s floor: the server\'s reason, and no way to sell him', (t) async {
    final m = FakeMarket();
    const why = 'لا بد أن يبقى في فريقك 4 مدافعين على الأقل.';
    final held = Selling.fromJson(json('market_pool')).mine.firstWhere((x) => x.line == 'def');
    final pl = MyPlayer(
      id: held.id,
      name: held.name,
      position: held.position,
      line: held.line,
      overall: held.overall,
      value: held.value,
      cost: held.cost,
      floor: held.floor,
      cap: held.cap,
      quickPays: held.quickPays,
      quickFee: held.quickFee,
      waitValue: held.waitValue,
      waitCap: held.waitCap,
      held: why,
    );
    await pump(
      t,
      Scaffold(
        body: SellSheet(player: pl, leagueId: 8, repo: m),
      ),
      m,
    );
    expect(find.text(why), findsOneWidget);
    expect(find.text('اعرضه للبيع'), findsNothing);
    expect(find.textContaining('بيع فوري'), findsNothing);
  });

  testWidgets('the scout: a report\'s players, one bought', (t) async {
    final m = FakeMarket();
    await pump(t, const ScoutScreen(leagueId: 8), m);
    expect(find.text('Santiago Giménez'), findsOneWidget);
    await t.tap(find.text('Santiago Giménez'));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('اشترِه بـ'));
    await t.pumpAndSettle();
    expect(m.sent, ['buy 8841']);
  });

  testWidgets('a new offer to a coach, a counter to his, a loan answered and a prospect signed', (t) async {
    final m = FakeMarket();
    await pump(t, const MarketScreen(leagueId: 8), m);
    await t.tap(find.text('العروض'));
    await t.pumpAndSettle();
    // The loan he asked for my player: accepted.
    await t.tap(find.text('اقبل').last);
    await t.pumpAndSettle();
    expect(m.sent, ['loan 4 true']);

    // A counter to Arsenal's offer: his Havertz for my Wirtz, as his offer named them, sent back to him.
    await t.tap(find.text('عرض مقابل'));
    await t.pumpAndSettle();
    await t.tap(find.text('أرسل العرض'));
    await t.pumpAndSettle();
    expect(m.sent.last, 'offer to:null counter:31 money:0 want:[5701] give:[5625]');

    await t.tap(find.text('الأكاديمية'));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('ضمّه بـ').first);
    await t.pumpAndSettle();
    await t.tap(find.text('تأكيد'));
    await t.pumpAndSettle();
    expect(m.sent.last, 'academy 3603');
  });

  testWidgets('a new offer: the club, his player asked for, sent', (t) async {
    final m = FakeMarket();
    await pump(t, const OfferScreen(leagueId: 8, clubId: 142, clubName: 'Arsenal'), m);
    await t.tap(find.text('David Raya'));
    await t.pump();
    await t.enterText(find.byType(TextField).first, '2000000');
    await t.pump();
    await t.tap(find.text('أرسل العرض'));
    await t.pumpAndSettle();
    expect(m.sent.last, 'offer to:142 counter:null money:2000000 want:[5650] give:[]');
  });
}
