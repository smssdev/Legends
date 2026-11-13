import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/tournaments/tournament_screens.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glm/api/gen/models.g.dart' as api;

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// A tournament made on a local server from the Africa Cup template (its page and draw), and the draw done in the
/// server's shape: four balls drawn a while ago, one every reveal_ms.
Map<String, dynamic> drawn() {
  final t = json('tournament')['tournament'] as Map<String, dynamic>;
  final teams = (t['teams'] as List<dynamic>).cast<Map<String, dynamic>>();
  final now = DateTime.now().millisecondsSinceEpoch;
  return {
    ...json('tournament_draw'),
    'drawn_at': DateTime.fromMillisecondsSinceEpoch(now - 60000).toUtc().toIso8601String(),
    'server_now': now,
    'steps': [
      for (final (i, c) in teams.take(4).indexed) {'type': 'group', 'club': c, 'pot': 1, 'group': i + 1, 'position': 1},
    ],
  };
}

Future<void> pump(WidgetTester t, Widget screen, {Map<String, dynamic>? draw}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(360 * 3, 2400 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  ClubCrest.loadFromNetwork = false;
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        tournamentsProvider.overrideWith(
          (ref) async => [for (final t in json('tournaments')['tournaments'] as List<dynamic>) api.Tournament.fromJson(t)],
        ),
        catalogProvider.overrideWith((ref) async => api.TournamentsCatalogAnswer.fromJson(json('tournaments_catalog'))),
        tournamentProvider.overrideWith((ref, id) async => api.TournamentPageAnswer.fromJson(json('tournament')).tournament),
        drawProvider.overrideWith((ref, id) async => api.TournamentsDrawAnswer.fromJson(draw ?? json('tournament_draw'))),
        allianceProvider.overrideWith(
          // [Sprint 59 F1] As the contract has it (AllianceAnswer), read through the generated model.
          (ref, id) async => api.AllianceAnswer.fromJson({
            'can_create': false,
            'sizes': [1, 5],
            'default_size': 2,
            'coaches': <dynamic>[],
            'tournament': {
              'id': 1,
              'name': 'Derby of alliances',
              'status': 'running',
              'my_club_id': 141,
              'swap_max': 3,
              'size': 2,
              'winner': null,
              'first_round_at': '2026-11-10T18:00:00Z',
              'review_note': null,
              'captain_of': 'a',
              'alliances': {
                'a': {'captain': 'Hamza', 'clubs': <dynamic>[]},
                'b': {'captain': 'Sulaiman', 'clubs': <dynamic>[]},
              },
              'ties': [
                {
                  'id': 7,
                  'round': 1,
                  'kind': 'match',
                  'home': {'id': 141, 'name': 'Liverpool', 'code': 'LIV', 'coach': 'Hamza', 'crest_url': '/crests/1.svg'},
                  'away': {'id': 142, 'name': 'Arsenal', 'code': 'ARS', 'coach': null, 'crest_url': '/crests/8.svg'},
                  'alliance': 'a',
                  'scheduled_at': '2026-11-10T18:00:00Z',
                  'status': 'scheduled',
                  'match_id': null,
                  'winner_id': null,
                  'score': null,
                },
                {
                  'id': 6,
                  'round': 0,
                  'kind': 'match',
                  'home': {'id': 141, 'name': 'Liverpool', 'code': 'LIV', 'coach': 'Hamza', 'crest_url': '/crests/1.svg'},
                  'away': {'id': 150, 'name': 'Chelsea', 'code': 'CHE', 'coach': null, 'crest_url': '/crests/4.svg'},
                  'alliance': 'a',
                  'scheduled_at': '2026-11-09T18:00:00Z',
                  'status': 'finished',
                  'match_id': 3,
                  'winner_id': 141,
                  'score': {'home': 2, 'away': 0},
                  'swaps': 1,
                },
              ],
            },
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
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('my tournaments, and a new one from a template', (t) async {
    await pump(t, const TournamentsScreen());
    expect(find.textContaining('بطولة #JGDTRRPS'), findsOneWidget);
    await pump(t, const NewTournamentScreen());
    await t.tap(find.textContaining('أمم أفريقيا'));
    await t.pump();
    expect(find.text('الكلفة 320 كوينز'), findsOneWidget);

    // Teams of my choice: two national teams picked by name.
    await t.tap(find.text('فرق من اختيارك'));
    await t.pump();
    await t.tap(find.text('France'));
    await t.pump();
    await t.tap(find.text('Spain'));
    await t.pump();
    expect(find.text('2 فريقاً مختاراً'), findsOneWidget);
    expect(find.text('الكلفة 40 كوينز'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a tournament\'s page: its code and its groups', (t) async {
    await pump(t, const TournamentScreen(id: 9));
    expect(find.text('JGDTRRPS'), findsOneWidget);
    expect(find.text('Egypt'), findsOneWidget);
    expect(find.text('المجموعة B'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the draw: not set yet for its organizer, then every ball on the shared clock', (t) async {
    await pump(t, const DrawScreen(id: 9));
    expect(find.text('لم يُحدَّد موعد القرعة'), findsOneWidget);
    expect(find.text('حدّد موعد القرعة'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await pump(t, const DrawScreen(id: 9), draw: drawn());
    expect(find.text('4 من 4'), findsOneWidget);
    expect(find.text('المجموعة D'), findsWidgets);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the alliance: my tie, and who goes on', (t) async {
    await pump(t, const AllianceScreen(leagueId: 8));
    expect(find.text('Derby of alliances'), findsOneWidget);
    expect(find.text('يتأهل: LIV'), findsOneWidget);
    expect(find.text('بادل لاعبين (حتى 2)'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
