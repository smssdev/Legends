import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/club/club_data.dart';
import 'package:glm/features/leagues/league_screen.dart';
import 'package:glm/features/leagues/leagues_repository.dart';
import 'package:glm/features/leagues/models.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The API's own answers, taken from a real local server (test/fixtures).
Map<String, dynamic> fixture(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  setUpAll(() => ClubCrest.loadFromNetwork = false);
  final league = League.fromJson(fixture('league')['league'] as Map<String, dynamic>);
  final table = [for (final r in fixture('standings')['table'] as List<dynamic>) StandingRow.fromJson(r as Map<String, dynamic>)];
  final fixtures = [for (final f in fixture('fixtures')['fixtures'] as List<dynamic>) Fixture.fromJson(f as Map<String, dynamic>)];
  final summary = ClubSummary.fromJson(fixture('summary'));

  test('a league, its table, its matches and my club read from the API as it answers', () {
    expect(league.isOwner, isTrue);
    expect(league.myClubId, isNotNull);
    expect(league.code, hasLength(8));
    expect(league.inviteUrl, contains('/join/${league.code}'));
    expect(table, hasLength(20));
    expect(table.first.position, 1);
    expect(fixtures.first.competition, 'league');
    expect(fixtures.first.at, isNotNull);
    expect(summary.club.id, league.myClubId);
    expect(summary.next, isNotNull);
    expect(summary.goal?.kind, isNotNull);
    final clubs = [for (final c in fixture('clubs')['clubs'] as List<dynamic>) ClubCardData.fromJson(c as Map<String, dynamic>)];
    expect(clubs.where((c) => !c.bot), hasLength(1));
    expect(clubs.first.goal, isNotNull);
  });

  testWidgets('the league page: my club, the table with my club marked, the matches and the invite', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await t.binding.setSurfaceSize(const Size(420, 1400));
    await t.pumpWidget(ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        leagueProvider(league.id).overrideWith((ref) async => league),
        clubSummaryProvider(league.id).overrideWith((ref) async => summary),
        standingsProvider(league.id).overrideWith((ref) async => table),
        fixturesProvider(league.id).overrideWith((ref) async => fixtures),
        requestsProvider(league.id).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: glmTheme(day: false),
        locale: const Locale('ar'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: LeagueScreen(id: league.id),
      ),
    ));
    await t.pumpAndSettle();
    // [Sprint 46] The hub: the next match's round on the stadium, the opponent's name.
    expect(find.text('الجولة 1'), findsOneWidget);
    expect(find.text(summary.next!.name), findsOneWidget);

    // The five sections at the bottom: the matches (calendar, then the table), and «more» with the coaches.
    await t.tap(find.widgetWithText(NavigationDestination, 'المباريات'));
    await t.pumpAndSettle();
    expect(find.text('الجولة 1'), findsOneWidget);
    await t.tap(find.widgetWithText(Tab, 'الترتيب'));
    await t.pumpAndSettle();
    expect(find.text(table.first.name), findsOneWidget);

    await t.tap(find.widgetWithText(NavigationDestination, 'المزيد'));
    await t.pumpAndSettle();
    expect(find.text(league.code), findsOneWidget);
    expect(find.text('طلبات الانضمام'), findsOneWidget);
  });
}
