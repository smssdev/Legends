import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/features/console/console_data.dart';
import 'package:glm/features/console/market_console.dart';
import 'package:glm/features/console/store_console.dart';
import 'package:glm/features/leagues/league_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:glm/ui/widgets/console.dart';

/// [Sprint 50] The console's new pieces with the server's answers faked: today's tasks claimed, an auction bid on, a
/// chest's odds shown and opened, and the report's two-colour bar.
class FakeConsole implements ConsoleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final List<String> sent = [];
  bool claimed = false;
  int top = 0;

  @override
  Future<DailyTasks> dailyTasks(int league) async => DailyTasks.fromJson({
    'day': '2026-11-10',
    'done': 1,
    'total': 4,
    'renews_at': '2026-11-10T22:00:00Z',
    'tasks': [
      {'task': 'lineup', 'complete': true, 'claimed': claimed, 'coins': 2},
      {'task': 'friendly', 'complete': false, 'claimed': false, 'coins': 3},
      {'task': 'training', 'complete': false, 'claimed': false, 'coins': 2},
      {'task': 'chat', 'complete': false, 'claimed': false, 'coins': 1},
    ],
  });

  @override
  Future<DailyTasks> claimTask(int league, String task) async {
    sent.add('claim $task');
    claimed = true;
    return dailyTasks(league);
  }

  @override
  Future<({List<Auction> auctions, List<int> minutes})> auctions(int league) async => (
    auctions: [
      Auction.fromJson({
        'player_id': 7,
        'name': 'L. Moreau',
        'position': 'CAM',
        'age': 23,
        'overall': 86,
        'value': 1000000,
        'club_id': 3,
        'club': 'Lions',
        'opening': 1000000,
        'top': top == 0 ? null : top,
        'bids': top == 0 ? 0 : 1,
        'next': top == 0 ? 1000000 : top + 20000,
        'max': 2000000,
        'mine': top == 0 ? null : top,
        'leading': top != 0,
        'ends_at': DateTime.now().add(const Duration(minutes: 12)).toUtc().toIso8601String(),
      }),
    ],
    minutes: [30, 60],
  );

  @override
  Future<Auction> bid(int league, int player, int amount) async {
    sent.add('bid $player $amount');
    top = amount;
    return (await auctions(league)).auctions.first;
  }

  @override
  Future<List<Chest>> chests(int league) async => [
    Chest.fromJson({
      'chest': 'bronze',
      'coins': 30,
      'odds': [
        {'reward': 'fitness', 'amount': 5, 'pct_bp': 6000},
        {'reward': 'coins', 'amount': 60, 'pct_bp': 4000},
      ],
    }),
  ];

  @override
  Future<({String reward, int amount})> openChest(int league, String chest) async {
    sent.add('open $chest');
    return (reward: 'coins', amount: 60);
  }
}

Future<void> pump(WidgetTester t, Widget child, FakeConsole fake, {Size size = const Size(860, 400), bool ticking = false}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  ClubCrest.loadFromNetwork = false;
  GlmModel3D.enabled = false;
  await t.pumpWidget(
    ProviderScope(
      overrides: [consoleRepositoryProvider.overrideWithValue(fake)],
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
        home: Scaffold(body: child),
      ),
    ),
  );
  if (ticking) {
    // A screen with a ticking countdown never settles: a few frames are enough.
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  } else {
    await t.pumpAndSettle();
  }
}

void main() {
  testWidgets("today's tasks: a done one claims its coins once", (t) async {
    final fake = FakeConsole();
    await pump(t, const SingleChildScrollView(child: DailyTasksCard(leagueId: 8)), fake);
    expect(find.text('المهام اليومية'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('اعتمد تشكيلتك أو تكتيكك'), findsOneWidget);
    await t.tap(find.widgetWithText(TextButton, '+2'));
    await t.pumpAndSettle();
    expect(fake.sent, ['claim lineup']);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
  });

  testWidgets('an auction: the list beside the card, and a bid at the next price', (t) async {
    final fake = FakeConsole();
    await pump(t, const AuctionsTab(leagueId: 8), fake, ticking: true);
    expect(find.text('L. Moreau'), findsWidgets);
    await t.tap(find.text('زايد 1M'));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(fake.sent, ['bid 7 1000000']);
    expect(find.text('الأعلى'), findsOneWidget);
    // The countdown keeps ticking: the test ends it.
    await t.pumpWidget(const SizedBox());
  });

  testWidgets("a chest's odds before it opens, and what it gave", (t) async {
    final fake = FakeConsole();
    await pump(t, const SingleChildScrollView(child: ChestsRow(leagueId: 8)), fake);
    expect(find.text('الصندوق البرونزي'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    await t.tap(find.text('افتح بـ 30 كوينز'));
    await t.pumpAndSettle();
    await t.tap(find.text('تأكيد').last);
    await t.pumpAndSettle();
    expect(fake.sent, ['open bronze']);
    expect(find.text('60 كوينز'), findsWidgets);
  });

  testWidgets("the report's bar: my side in mint, theirs in orange, the figure between", (t) async {
    await pump(
      t,
      const Center(
        child: SizedBox(
          width: 500,
          child: GlmDualCompareBar(label: 'الاستحواذ', mine: 58, theirs: 42, mineText: '58%', theirsText: '42%'),
        ),
      ),
      FakeConsole(),
    );
    expect(find.text('58%'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.bySemanticsLabel('الاستحواذ: 58% - 42%'), findsOneWidget);
  });
}
