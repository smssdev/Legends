import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/club/extras_data.dart';
import 'package:glm/features/club/training_screen.dart';
import 'package:glm/features/club/specialists_screen.dart';
import 'package:glm/features/club/spy_screen.dart';
import 'package:glm/features/club/quests_screen.dart';
import 'package:glm/features/club/honours_screen.dart';
import 'package:glm/features/coach/coach_profile_screen.dart';
import 'package:glm/features/wallet/wallet_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glm/api/gen/models.g.dart' as api;

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Real replies from a local server (league 8; the spy's report in the server's shape), and what the screens send.
class FakeExtras implements ExtrasRepository {
  final List<String> sent = [];
  bool spied = false;

  @override
  Future<TrainingView> training(int league) async => TrainingView.fromJson(json('training'));
  @override
  Future<TrainingView> train(int league, int player, {bool replace = false}) async {
    sent.add('train $player${replace ? ' replace' : ''}');
    return training(league);
  }

  @override
  Future<TrainingView> stopTraining(int league, String line) async => training(league);
  @override
  Future<TrainingView> finishTraining(int league, String line) async => training(league);
  @override
  Future<({int days, List<Specialist> list})> specialists(int league) async {
    return ExtrasRepository.readSpecialists(json('specialists'));
  }

  @override
  Future<void> hire(int league, String type, int stars) async => sent.add('hire $type $stars');
  @override
  Future<SpyView> spy(int league) async => SpyView.fromJson({
    ...json('spy'),
    if (spied)
      'report': {
        'club': {'id': 160, 'name': 'Burnley'},
        'at': '2026-11-08T18:00:00Z',
        'formation': '4-4-2',
        'fitness': 93,
        'form': ['W', 'L'],
        'tactics': {'plan': 'counter', 'marking': 'zone', 'tackling': 1, 'trap': 0},
        'starters': [
          {'id': 1, 'name': 'Zian Flemming', 'position': 'ST', 'line': 'att', 'overall': 77},
        ],
        'bench': <dynamic>[],
      },
  });
  @override
  Future<SpyView> sendSpy(int league) async {
    spied = true;
    sent.add('spy');
    return spy(league);
  }

  @override
  Future<({DateTime? renewsAt, List<Quest> quests})> quests(int league) async {
    return ExtrasRepository.readQuests(json('quests'));
  }

  @override
  Future<void> claimQuest(int league, String quest) async => sent.add('claim $quest');
  @override
  Future<List<({int number, List<({String competition, int position, String club, String? coach})> titles})>> honours(int league) async => [
    (number: 1, titles: const [(competition: 'league', position: 1, club: 'Liverpool', coach: 'Suleiman')]),
  ];
  @override
  Future<void> resign(int league) async => sent.add('resign');
  @override
  Future<Map<String, int>> prices() async => {
    for (final e in (json('wallet')['prices'] as Map<dynamic, dynamic>).entries) '${e.key}': e.value as int,
  };
}

class FakeWallet implements WalletRepository {
  int claims = 0;

  @override
  Future<WalletView> wallet() async => WalletView.fromJson({
    ...json('wallet'),
    'daily': {'amount': 10, 'claimed': claims > 0},
  });
  @override
  Future<void> claimDaily() async => claims++;
  @override
  Future<List<StoreItem>> store() async => StoreItem.shown(json('store'));
}

Future<void> pump(WidgetTester t, Widget screen, {FakeExtras? extras, FakeWallet? wallet}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(360 * 3, 2000 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  ClubCrest.loadFromNetwork = false;
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        extrasRepositoryProvider.overrideWithValue(extras ?? FakeExtras()),
        walletRepositoryProvider.overrideWithValue(wallet ?? FakeWallet()),
        coachProfileProvider.overrideWith(
          (ref, id) async => api.CoachProfile.fromJson({
            ...json('coach'),
            'titles': [
              {'league': 'Premier League', 'season': 1, 'competition': 'league', 'position': 1, 'club': 'Liverpool'},
            ],
          }),
        ),
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
  testWidgets('training: the goalkeeper in training, a defender put in with the suggested one first', (t) async {
    final x = FakeExtras();
    await pump(t, const TrainingScreen(leagueId: 8), extras: x);
    expect(find.textContaining('Ármin Pécsi'), findsOneWidget);
    expect(find.text('أنهِه الآن (5 كوينز)'), findsOneWidget);
    // [Sprint 64 B4] A session's spend before it is made.
    expect(find.textContaining('يبقى بعده'), findsOneWidget);
    await t.tap(find.text('اختر من يتدرب').at(1));
    await t.pumpAndSettle();
    expect(find.text('المقترح'), findsOneWidget);
    await t.tap(find.text('المقترح'));
    await t.pumpAndSettle();
    expect(x.sent, ['train 5604']);
  });

  testWidgets('the spy: sent after a yes, then his report', (t) async {
    final x = FakeExtras();
    await pump(t, const SpyScreen(leagueId: 8), extras: x);
    expect(find.text('Burnley'), findsOneWidget);
    await t.tap(find.text('أرسل الجاسوس (20 كوينز)'));
    await t.pumpAndSettle();
    await t.tap(find.text('تأكيد'));
    await t.pumpAndSettle();
    expect(x.sent, ['spy']);
    expect(find.text('تقرير عن Burnley'), findsOneWidget);
    expect(find.text('Zian Flemming'), findsOneWidget);
  });

  testWidgets('the quests: a complete one claimed; the specialists and honours shown', (t) async {
    final x = FakeExtras();
    await pump(t, const QuestsScreen(leagueId: 8), extras: x);
    // Only the stadium quest is complete: the third.
    await t.tap(find.text('استلم').at(2));
    await t.pumpAndSettle();
    expect(x.sent, ['claim stadium']);

    await pump(t, const SpecialistsScreen(leagueId: 8), extras: x);
    expect(find.text('مدرب الهجوم'), findsOneWidget);
    await pump(t, const HonoursScreen(leagueId: 8), extras: x);
    expect(find.text('Liverpool'), findsOneWidget);
  });

  testWidgets('the wallet: today\'s coins claimed, and the store\'s offer to order on WhatsApp', (t) async {
    final w = FakeWallet();
    await pump(t, const WalletScreen(), wallet: w);
    expect(find.text('باقة 1000 كوينز'), findsOneWidget);
    expect(find.text('اطلب عبر واتساب'), findsWidgets);
    await t.tap(find.text('استلم كوينز اليوم'));
    await t.pumpAndSettle();
    expect(w.claims, 1);
    expect(find.text('استلمت كوينز اليوم'), findsOneWidget);
  });

  testWidgets('a coach\'s profile: his record and titles', (t) async {
    await pump(t, const CoachProfileScreen(userId: 16));
    expect(find.text('حساب رقم 34537'), findsOneWidget);
    // [Sprint 64 F10] Between us, from the matches.
    expect(find.text('بيني وبينه'), findsOneWidget);
    expect(find.text('لعبتما 3: فزت 1، وتعادلتما 1، وخسرت 1'), findsOneWidget);
    expect(find.text('Liverpool'), findsOneWidget);
    expect(find.text('أهداف الإدارة: 0 من 0'), findsOneWidget);
  });
}
