import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/market/market_data.dart';
import 'package:glm/features/market/market_screen.dart';
import 'package:glm/features/market/scout_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Real replies from a local server (the offers written in the server's shape), and what the screens send.
class FakeMarket implements MarketRepository {
  final List<String> sent = [];

  @override
  Future<({List<MarketPlayer> players, DateTime? renewsAt, int balance, String? closed})> list(int league, String line) async {
    final j = json('market');
    return (players: [for (final p in j['players'] as List) MarketPlayer.fromJson(p as Map<String, dynamic>)], renewsAt: DateTime.tryParse('${j['renews_at']}'), balance: 0, closed: null);
  }

  @override
  Future<BuyQuote> buyQuote(int league, int player) async =>
      BuyQuote.fromJson({'price': 530000, 'cash': 2971870, 'doc_coins': 1, 'short': 0, 'compensate': null, 'can': true, 'why': null});
  @override
  Future<void> buy(int league, int player, {bool compensate = false}) async => sent.add('buy $player');
  @override
  Future<Selling> selling(int league) async => Selling.fromJson(json('market_pool'));
  @override
  Future<({int floor, int cap, bool ok, int waitHours})> sellQuote(int league, int player, int price) async => (floor: 1, cap: 2, ok: true, waitHours: 6);
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
  t.view.physicalSize = const Size(360 * 3, 1800 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: [preferencesProvider.overrideWithValue(prefs), marketRepositoryProvider.overrideWithValue(market), scoutRepositoryProvider.overrideWithValue(FakeScout())],
    child: MaterialApp(
      theme: glmTheme(day: false),
      locale: const Locale('ar'),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: screen,
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  test('the market, my players for sale and the offers from the API', () {
    final s = Selling.fromJson(json('market_pool'));
    expect(s.mine, isNotEmpty);
    expect(s.mine.first.cap, greaterThan(s.mine.first.floor));
    expect(s.mine.first.quickFee.currency, 'coins');
    final d = Deals.fromJson(json('offers'));
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
    await t.tap(find.text('اقبل'));
    await t.pumpAndSettle();
    expect(m.sent.last, 'accept 31');
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
}
