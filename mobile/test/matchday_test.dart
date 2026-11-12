import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/club/matchday_screens.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Real replies from a local server (league 8's next match, its press conference opened, the integrity panel after a
/// security check, the contracts and the cheer tickets).
Future<void> pump(WidgetTester t, Widget screen) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(360 * 3, 3000 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  ClubCrest.loadFromNetwork = false;
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        nextMatchProvider.overrideWith((ref, l) async => json('next_match')['match'] as Map<String, dynamic>),
        pressProvider.overrideWith((ref, k) async => {...json('press_2794')['press'] as Map<String, dynamic>, 'open': true}),
        integrityProvider.overrideWith(
          (ref, l) async => {
            ...json('integrity'),
            'security': {
              'sees': true,
              'cost': {'currency': 'coins', 'amount': 10},
            },
            'spies_on_me': [
              {'id': 3, 'club': 'Burnley', 'turned': false},
            ],
          },
        ),
        contractsProvider.overrideWith((ref, l) async => json('team_contracts')),
        ticketsProvider.overrideWith((ref, l) async => json('tickets')),
        missedProvider.overrideWith(
          (ref, l) async => [
            {
              'match_id': 77,
              'result': 1,
              'home': {'name': 'Liverpool'},
              'away': {'name': 'Arsenal'},
              'home_goals': 2,
              'away_goals': 1,
              'goals': [
                {'minute': 18, 'side': 'home', 'scorer': 'Mohamed Salah'},
              ],
              'man_of_the_match': {'name': 'Mohamed Salah'},
              'coins': 3,
              'changes': [
                {'kind': 'injury', 'player': 'Cody Gakpo'},
              ],
            },
          ],
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
  testWidgets('match day: the move\'s hours, the press conference and the spies on my match', (t) async {
    await pump(t, const MatchdayScreen(leagueId: 8));
    expect(find.text('Burnley'), findsWidgets);
    expect(find.text('قدّم المباراة أو أخّرها'), findsOneWidget);
    expect(find.textContaining('أبكر 6 س'), findsOneWidget);
    expect(find.text('المؤتمر الصحفي'), findsOneWidget);
    expect(find.textContaining('الحظوظ: فوز 73%'), findsOneWidget);
    expect(find.textContaining('سنلعب من أجل الفوز الكاسح'), findsOneWidget);
    expect(find.textContaining('ادفع للحكم'), findsOneWidget);
    expect(find.text('اتهمه'), findsOneWidget);
  });

  testWidgets('the contracts and the cheer tickets', (t) async {
    await pump(t, const ContractsScreen(leagueId: 8));
    expect(find.text('Florian Wirtz'), findsOneWidget);
    expect(find.textContaining('فسخ العقد'), findsWidgets);
    await pump(t, const TicketsScreen(leagueId: 8));
    expect(find.text('Leeds United'), findsWidgets);
    expect(find.text('شجّع'), findsWidgets);
  });

  testWidgets('what I missed: the result, its scorer, the coins and an injury', (t) async {
    await pump(t, const MissedScreen(leagueId: 8));
    expect(find.text('2 - 1'), findsOneWidget);
    expect(find.textContaining('Mohamed Salah'), findsWidgets);
    expect(find.text('3 كوينز'), findsOneWidget);
    expect(find.textContaining('Cody Gakpo'), findsOneWidget);
  });
}
