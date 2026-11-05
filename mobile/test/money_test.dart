import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/inbox/inbox_data.dart';
import 'package:glm/features/inbox/inbox_screen.dart';
import 'package:glm/features/money/finance_screen.dart';
import 'package:glm/features/money/money_data.dart';
import 'package:glm/features/money/stadium_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Real replies from a local server (league 8), and what the screens send.
class FakeMoney implements MoneyRepository {
  final List<String> sent = [];
  bool building = false;

  @override
  Future<Finance> finance(int league) async => Finance.fromJson(json('finance'));
  @override
  Future<void> signSponsor(int league, String sector, String offer) async => sent.add('sponsor $sector $offer');
  @override
  Future<void> setTickets(int league, String level) async => sent.add('tickets $level');
  @override
  Future<StadiumView> stadium(int league) async => StadiumView.fromJson(json(building ? 'stadium_building' : 'stadium'));
  @override
  Future<StadiumView> build(int league, String section) async {
    sent.add('build $section');
    return StadiumView.fromJson(json('stadium_building'));
  }

  @override
  Future<StadiumView> finishNow(int league) async {
    sent.add('finish');
    return StadiumView.fromJson(json('stadium'));
  }
}

class FakeInbox implements InboxRepository {
  final List<int> reads = [];

  @override
  Future<InboxPage> page({int? before}) async => InboxPage.fromJson(json('messages'));
  @override
  Future<int> unread() async => 1;
  @override
  Future<void> read(int id) async => reads.add(id);
  @override
  Future<void> readAll() async {}
}

Future<void> pump(WidgetTester t, Widget screen, {FakeMoney? money, FakeInbox? inbox, GoRouter? router}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(360 * 3, 2400 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: [
      preferencesProvider.overrideWithValue(prefs),
      if (money != null) moneyRepositoryProvider.overrideWithValue(money),
      if (inbox != null) inboxRepositoryProvider.overrideWithValue(inbox),
    ],
    child: router != null
        ? MaterialApp.router(
            theme: glmTheme(day: false),
            locale: const Locale('ar'),
            supportedLocales: L.supportedLocales,
            localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
            routerConfig: router,
          )
        : MaterialApp(
            theme: glmTheme(day: false),
            locale: const Locale('ar'),
            supportedLocales: L.supportedLocales,
            localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
            home: screen,
          ),
  ));
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('the finance and the stadium from the API', () {
    final f = Finance.fromJson(json('finance'));
    expect(f.balance, 3000000);
    expect(f.tickets.levels, hasLength(4));
    expect(f.sponsors.first.offers, hasLength(3));
    final s = StadiumView.fromJson(json('stadium_building'));
    expect(s.sections, hasLength(3));
    expect(s.building!.section, 'seats');
    expect(s.building!.finishCoins, 10);
  });

  test('a message leads to its screen in its league', () {
    final m = InboxPage.fromJson(json('messages')).messages.first;
    expect(m.route, '/leagues/8/stadium');
  });

  testWidgets('the finance: the balance, the ticket price, a sponsor signed after a yes', (t) async {
    final money = FakeMoney();
    await pump(t, const FinanceScreen(leagueId: 8), money: money);
    expect(find.text('3M'), findsOneWidget);
    await t.tap(find.text('مميز'));
    await t.pump();
    expect(money.sent, ['tickets premium']);
    await t.tap(find.text('طموح: أقل ثابتاً وأكثر عند الفوز').first);
    await t.pumpAndSettle();
    await t.tap(find.text('تأكيد'));
    await t.pumpAndSettle();
    expect(money.sent.last, 'sponsor main ambitious');
  });

  testWidgets('the stadium: build a part, then it is under way with its price to finish now', (t) async {
    final money = FakeMoney();
    await pump(t, const StadiumScreen(leagueId: 8), money: money);
    expect(find.text('التذاكر والمقاعد'), findsOneWidget);
    await t.tap(find.textContaining('ابنِ').first);
    await t.pump(const Duration(milliseconds: 300));
    expect(money.sent, ['build seats']);
    expect(find.textContaining('يُبنى الآن'), findsOneWidget);
    expect(find.text('أنهِه الآن (10 كوينز)'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the inbox: a message read on a tap', (t) async {
    final inbox = FakeInbox();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const InboxScreen()),
      GoRoute(path: '/leagues/:id/stadium', builder: (_, s) => Scaffold(body: Text('stadium ${s.pathParameters['id']}'))),
    ]);
    await pump(t, const SizedBox(), inbox: inbox, router: router);
    expect(find.text('اكتمل جزء في الملعب'), findsOneWidget);
    await t.tap(find.text('اكتمل جزء في الملعب'));
    await t.pumpAndSettle();
    expect(inbox.reads, [1]);
    expect(find.text('stadium 8'), findsOneWidget);
  });
}
