import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/settings.dart';
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
  final List<Map<String, Object>> tacticsSent = [];
  List<int>? startersSent;

  @override
  Future<TeamData> team(int league) async => sample;
  @override
  Future<List<Formation>> formations() async => [Formation(name: sample.lineup.formation, label: sample.lineup.formation, slots: sample.lineup.slots)];
  @override
  Future<TeamData> saveLineup(int league, String formation, List<int> starters, List<int> bench) async {
    startersSent = starters;
    return sample;
  }
  @override
  Future<TeamData> autoLineup(int league) async => sample;
  @override
  Future<Tactics> tactics(int league) async => const Tactics({'plan': 'passing', 'tackling': 1, 'pressing': 50, 'style': 50, 'tempo': 50, 'att': 'support', 'mid': 'stay', 'def': 'stay', 'trap': 0, 'marking': 'zone'});
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
  await t.pumpWidget(ProviderScope(
    overrides: [preferencesProvider.overrideWithValue(prefs), teamRepositoryProvider.overrideWithValue(repo)],
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
  });

  testWidgets('the lineup: two players swapped, then saved with the new eleven', (t) async {
    final repo = FakeTeamRepository();
    await pump(t, const LineupScreen(leagueId: 1), repo);
    final starter = sample.byId(sample.lineup.starters[5])!;
    final sub = sample.byId(sample.lineup.bench[2])!;
    await t.tap(find.text(starter.name.split(' ').last).first);
    await t.pump();
    await t.tap(find.text(sub.name));
    await t.pump();
    await t.tap(find.text('احفظ'));
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
    await t.tap(find.text('احفظ'));
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
    expect(repo.tacticsSent, [{'plan': 'counter'}]);
  });
}
