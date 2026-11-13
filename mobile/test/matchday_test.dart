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
import 'package:glm/api/gen/models.g.dart' as api;

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
        // [Sprint 59 F1] The referee as the server sends it: his strictness, a word.
        nextMatchProvider.overrideWith(
          (ref, l) async => api.NextMatch.fromJson({...json('next_match')['match'] as Map<String, dynamic>, 'referee': 'strict'}),
        ),
        pressProvider.overrideWith(
          (ref, k) async => api.PressConference.fromJson({...json('press_2794')['press'] as Map<String, dynamic>, 'open': true}),
        ),
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
        contractsProvider.overrideWith((ref, l) async => api.Contracts.fromJson(json('team_contracts'))),
        ticketsProvider.overrideWith((ref, l) async => json('tickets')),
        missedProvider.overrideWith(
          (ref, l) async => [
            // [Sprint 59 F1] As the contract has it (MissedMatch), read through the generated model.
            api.MissedMatch.fromJson({
              'match_id': 77,
              'competition': 'league',
              'round': 3,
              'venue': 'home',
              'at': '2026-11-08T19:00:00Z',
              'result': 1,
              'home': {'id': 141, 'name': 'Liverpool', 'code': 'LIV', 'crest_url': '/crests/1.svg'},
              'away': {'id': 142, 'name': 'Arsenal', 'code': 'ARS', 'crest_url': '/crests/8.svg'},
              'home_goals': 2,
              'away_goals': 1,
              'goals': [
                {'minute': 18, 'side': 'home', 'scorer': 'Mohamed Salah'},
              ],
              'man_of_the_match': {'id': 1, 'name': 'Mohamed Salah', 'rating': 820, 'mine': true},
              'coins': 3,
              'changes': [
                {'kind': 'injury', 'player': 'Cody Gakpo'},
              ],
              'mood': 'joy',
            }),
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
    expect(find.textContaining(': صارم'), findsOneWidget, reason: 'the referee drawn for the match');
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
