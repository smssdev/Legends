import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/club/takers_screen.dart';
import 'package:glm/features/club/lineup_screen.dart';
import 'package:glm/features/club/squad_screen.dart';
import 'package:glm/features/club/tactics_screen.dart';
import 'package:glm/features/club/team_data.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sample = TeamData.fromJson(jsonDecode(File('test/fixtures/team.json').readAsStringSync()) as Map<String, dynamic>);

/// Records what the screens send, answers as the API would.
class FakeTeamRepository implements TeamRepository {
  Map<String, int?>? takersSent;
  @override
  Future<TeamData> saveTakers(int league, Map<String, int?> roles) async {
    takersSent = roles;
    return sample;
  }

  final List<Map<String, Object>> tacticsSent = [];
  List<int>? startersSent;

  @override
  Future<TeamData> team(int league, {void Function()? onNewer}) async => sample;
  @override
  Future<RivalSquad> rival(int league, int club) async =>
      RivalSquad(id: club, name: 'Rivals FC', code: 'RIV', crestUrl: '', team: sample, coach: 'Coach');
  @override
  Future<List<Formation>> formations() async => [
    Formation(name: sample.lineup.formation, label: sample.lineup.formation, slots: sample.lineup.slots),
  ];
  @override
  Future<TeamData> saveLineup(int league, String formation, List<int> starters, List<int> bench, {List<List<int>>? positions}) async {
    startersSent = starters;
    return sample;
  }

  @override
  Future<TeamData> autoLineup(int league) async => sample;
  @override
  Future<Tactics> tactics(int league) async => const Tactics({
    'plan': 'passing',
    'tackling': 1,
    'pressing': 50,
    'style': 50,
    'tempo': 50,
    'att': 'support',
    'mid': 'stay',
    'def': 'stay',
    'trap': 0,
    'marking': 'zone',
  });
  @override
  Future<Tactics> saveTactics(int league, Map<String, Object> changes) async {
    tacticsSent.add(changes);
    return await tactics(league);
  }
}

Future<void> pump(WidgetTester t, Widget screen, FakeTeamRepository repo) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await t.binding.setSurfaceSize(const Size(420, 2400));
  await t.pumpWidget(
    ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(prefs), teamRepositoryProvider.overrideWithValue(repo)],
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
  test('the team from the API: the squad, the eleven in slot order and the bench', () {
    expect(sample.players.length, greaterThan(18));
    expect(sample.lineup.starters, hasLength(11));
    expect(sample.lineup.slots, hasLength(11));
    expect(sample.byId(sample.lineup.starters.first)!.line, 'gk');
    expect(sample.players.first.attributes, isNotEmpty);
  });

  testWidgets('the squad by line, and a player card', (t) async {
    await pump(t, const SquadScreen(leagueId: 1), FakeTeamRepository());
    // [Sprint 46] Grouped as the manager games list them: forwards first, the goalkeepers last.
    expect(find.text('المهاجمون'), findsOneWidget);
    final first = sample.players.first;
    await t.scrollUntilVisible(find.text(first.name), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('حراس المرمى'), findsOneWidget);
    await t.tap(find.text(first.name));
    await t.pumpAndSettle();
    expect(find.text('المهارات'), findsOneWidget);
    // [X105] My player is sold from his card, as on the site, not from the market only.
    expect(find.text('بيع اللاعب'), findsOneWidget);
  });

  testWidgets('[X105] another club of the league in the same table: its name and players, an offer from a card, no sale', (t) async {
    await pump(t, const SquadScreen(leagueId: 1, clubId: 7), FakeTeamRepository());
    expect(find.text('Rivals FC'), findsWidgets);
    expect(find.text('المدرب Coach'), findsOneWidget);
    expect(find.text('فريقي'), findsOneWidget);
    expect(find.text('فرق الخصوم'), findsOneWidget);
    final first = sample.players.first;
    await t.scrollUntilVisible(find.text(first.name), 300, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text(first.name));
    await t.pumpAndSettle();
    expect(find.text('اطلبه بعرض'), findsOneWidget);
    expect(find.text('بيع اللاعب'), findsNothing);
  });

  testWidgets('[Sprint 60 F4] landscape: the card is a panel beside the table, another row swaps it', (t) async {
    await pump(t, const SquadScreen(leagueId: 1), FakeTeamRepository());
    await t.binding.setSurfaceSize(const Size(1000, 2400));
    await t.pumpAndSettle();
    final first = sample.players.first, other = sample.players[1];
    await t.ensureVisible(find.text(first.name));
    await t.pumpAndSettle();
    await t.tap(find.text(first.name));
    await t.pumpAndSettle();
    expect(find.byType(PlayerCardPanel), findsOneWidget);
    expect(find.text('حراس المرمى'), findsOneWidget);
    // [Sprint 72 R6] Beside the open card the table is narrower: his row may show «F. Last» or the last name alone.
    final row = find.textContaining(other.name.split(' ').last).first;
    await t.ensureVisible(row);
    await t.pumpAndSettle();
    await t.tap(row);
    await t.pumpAndSettle();
    expect(find.descendant(of: find.byType(PlayerCardPanel), matching: find.text(other.name)), findsOneWidget);
    await t.tap(find.byTooltip('إغلاق'));
    await t.pumpAndSettle();
    expect(find.byType(PlayerCardPanel), findsNothing);
  });

  testWidgets('[Sprint 60 F4] the takers: the four roles, and a player chosen for one goes with the others as they were', (t) async {
    final repo = FakeTeamRepository();
    await pump(t, const TakersScreen(leagueId: 1), repo);
    for (final role in ['قائد الفريق', 'ضربات الجزاء', 'الضربات الحرة', 'الركنيات']) {
      expect(find.text(role), findsOneWidget);
    }
    final penalty = sample.takers['penalty']!;
    final pick = penalty.candidates.firstWhere((c) => c.id != penalty.playerId);
    await t.tap(find.text('تبديل اللاعب').at(1));
    await t.pumpAndSettle();
    await t.tap(find.text(sample.byId(pick.id)!.name).last);
    await t.pumpAndSettle();
    expect(repo.takersSent!['penalty'], pick.id);
    expect(repo.takersSent!['captain'], sample.takers['captain']!.chosenId);
  });

  testWidgets('the lineup: two players swapped, then saved by itself with the new eleven', (t) async {
    final repo = FakeTeamRepository();
    await pump(t, const LineupScreen(leagueId: 1), repo);
    final starter = sample.byId(sample.lineup.starters[5])!;
    final sub = sample.byId(sample.lineup.bench[2])!;
    await t.tap(find.text(starter.name.split(' ').last).first);
    await t.pump();
    await t.tap(find.text(sub.name));
    await t.pump();
    // [Sprint 60 F4] The lineup saves itself a moment after the change.
    expect(repo.startersSent, isNull);
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(repo.startersSent![5], sub.id);
  });

  testWidgets('the lineup: a bench player held and dropped on one of the eleven takes his place', (t) async {
    final repo = FakeTeamRepository();
    await pump(t, const LineupScreen(leagueId: 1), repo);
    final starter = sample.byId(sample.lineup.starters[5])!;
    final sub = sample.byId(sample.lineup.bench[2])!;
    final g = await t.startGesture(t.getCenter(find.text(sub.name)));
    await t.pump(const Duration(milliseconds: 700));
    await g.moveTo(t.getCenter(find.text(starter.name.split(' ').last).first));
    await t.pump();
    await g.up();
    await t.pump();
    // [Sprint 60 F4] The lineup saves itself a moment after the change.
    expect(repo.startersSent, isNull);
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(repo.startersSent![5], sub.id);
  });

  testWidgets('the tactics save themselves after a change', (t) async {
    final repo = FakeTeamRepository();
    await pump(t, const TacticsScreen(leagueId: 1), repo);
    // [Sprint 46] The plan is turned with its arrows: from passes back twice to the counter-attack.
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byIcon(Icons.chevron_right_rounded).first);
      await t.pump();
    }
    expect(find.text('هجوم مرتد'), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    expect(repo.tacticsSent, [
      {'plan': 'counter'},
    ]);
  });
}
