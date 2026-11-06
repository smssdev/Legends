@Tags(["shots"])
library;

// Screenshots of the app's screens with the real fonts, for design review: flutter test test/shots --update-goldens
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/club/club_data.dart';
import 'package:glm/features/club/squad_screen.dart';
import 'package:glm/features/club/team_data.dart';
import 'package:glm/features/home/home_data.dart';
import 'package:glm/features/home/home_screen.dart';
import 'package:glm/features/leagues/league_screen.dart';
import 'package:glm/features/leagues/leagues_repository.dart';
import 'package:glm/features/leagues/models.dart';
import 'package:glm/features/match/live_screen.dart';
import 'package:glm/features/match/match_data.dart';
import 'package:glm/features/market/market_data.dart';
import 'package:glm/features/market/market_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../market_test.dart' show FakeMarket;
import '../match_test.dart' show FakeMatchRepository;
import '../team_test.dart' show FakeTeamRepository;

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

Future<void> fonts() async {
  for (final (family, files) in [
    ('Tajawal', ['Tajawal-400', 'Tajawal-500', 'Tajawal-700', 'Tajawal-800']),
    ('BarlowCondensed', ['BarlowCondensed-600', 'BarlowCondensed-700', 'BarlowCondensed-800']),
  ]) {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f.ttf').readAsBytesSync())));
    }
    await l.load();
  }
  final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('/opt/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

const homeJson = {
  'coach': {'name': 'حمزة', 'coins': 1250, 'account_no': 48213, 'record': {'won': 7, 'drawn': 2, 'lost': 1}, 'rating': {'points': 420, 'tier': {'key': 'professional', 'division': 3}}},
  'slots_open': 3,
  'starter_gift': {'coins': 25, 'claimed': false},
  'slots': [
    {'slot': 1, 'state': 'club', 'league': {'id': 8, 'name': 'Premier League'}, 'club': {'id': 141, 'name': 'Liverpool', 'code': 'LIV'}, 'position': 2, 'teams': 20, 'next': {'opponent': {'name': 'Arsenal', 'code': 'ARS'}, 'home': true, 'scheduled_at': '2026-11-08T19:00:00Z'}},
    {'slot': 2, 'state': 'free'},
    {'slot': 3, 'state': 'locked', 'opens_at': '2030-01-01T00:00:00Z', 'unlock_coins': 50},
  ],
};

Future<void> shot(WidgetTester t, String name, Widget screen, List overrides, {double h = 800}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = Size(390 * 2, h * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  ClubCrest.loadFromNetwork = false;
  await t.runAsync(fonts);
  await t.pumpWidget(ProviderScope(
    overrides: [preferencesProvider.overrideWithValue(prefs), ...overrides],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: glmTheme(day: false),
      locale: const Locale('ar'),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: screen,
    ),
  ));
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));
  await t.pumpWidget(const SizedBox());
}

void main() {
  testWidgets('home', (t) => shot(t, 'home', const HomeScreen(), [homeProvider.overrideWith((ref) async => HomeData.fromJson(homeJson))]));
  testWidgets('league', (t) => shot(t, 'league', const LeagueScreen(id: 8), [
        leagueProvider.overrideWith((ref, id) async => League.fromJson(json('league')['league'] as Map<String, dynamic>)),
        clubSummaryProvider.overrideWith((ref, id) async => ClubSummary.fromJson(json('summary'))),
      ], h: 1400));
  testWidgets('squad', (t) => shot(t, 'squad', const SquadScreen(leagueId: 8), [teamRepositoryProvider.overrideWithValue(FakeTeamRepository())]));
  testWidgets('market', (t) => shot(t, 'market', const MarketScreen(leagueId: 8), [marketRepositoryProvider.overrideWithValue(FakeMarket())]));
  testWidgets('live', (t) => shot(t, 'live', const LiveMatchScreen(matchId: 77), [matchRepositoryProvider.overrideWithValue(FakeMatchRepository())]));
}
