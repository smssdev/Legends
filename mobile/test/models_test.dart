import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glm/api/gen/models.g.dart' hide MatchView, TrainingView;
import 'package:glm/api/read.dart';
import 'package:glm/features/club/extras_data.dart';
import 'package:glm/features/club/team_data.dart';
import 'package:glm/features/match/match_data.dart';

// [Sprint 59 F1, F2] The generated models read tolerantly: a new field the app does not know changes nothing, a
// missing optional one reads as null, and a missing required one is one clear error naming the model and the field.
void main() {
  final quote = {'price': 530000, 'cash': 2971870, 'doc_coins': 1, 'short': 0, 'compensate': null, 'can': true, 'why': null};

  test('the buy quote, with a field the app does not know yet', () {
    final q = BuyQuote.fromJson({
      ...quote,
      'new_field': 'later',
      'compensate': {'cash': 10, 'coins': 2},
    });
    expect(q.price, 530000);
    expect(q.docCoins, 1);
    expect(q.compensate!.coins, 2);
    expect(q.why, isNull);
  });

  test('a missing required field is one clear error', () {
    expect(
      () => BuyQuote.fromJson({...quote}..remove('price')),
      throwsA(isA<ModelError>().having((e) => '$e', 'message', 'ModelError: BuyQuote.price is missing')),
    );
    expect(modelErrors, contains('ModelError: BuyQuote.price is missing'));
  });

  test('a wrong optional field reads as null, and a number sent as a decimal reads as an int', () {
    final q = BuyQuote.fromJson({
      ...quote,
      'why': ['not', 'text'],
      'cash': 12.0,
    });
    expect(q.why, isNull);
    expect(q.cash, 12);
  });

  test('a list keeps the items that read and leaves out the one that does not', () {
    final m = MarketBotsItem.fromJson({'id': 1, 'name': 'X', 'code': 'X', 'players': 18});
    expect(m.players, 18);
    final r = JsonReader({
      'bots': [
        {'id': 1, 'name': 'A', 'code': 'A', 'players': 18},
        {'id': 2, 'code': 'B'},
      ],
    }, 'Test');
    expect(r.list('bots', MarketBotsItem.fromJson).map((b) => b.id), [1]);
  });

  test('a squad player: the overall as the server counts it (training once), and his flag', () {
    final team = TeamData.fromJson(jsonDecode(File('test/fixtures/team.json').readAsStringSync()) as Map<String, dynamic>);
    expect(team.players, isNotEmpty);
    final raw = (jsonDecode(File('test/fixtures/team.json').readAsStringSync()) as Map<String, dynamic>)['players'] as List<dynamic>;
    final first = Map<String, dynamic>.from(raw.first as Map<dynamic, dynamic>)
      ..['overall'] = 80
      ..['training_bonus'] = 3;
    expect(Player.of(SquadPlayer.fromJson(first)).overall, 80, reason: 'overall already has the training in it');
  });

  test('a league match: the captured answer reads through LeagueMatch with nothing left out', () {
    final raw = jsonDecode(File('test/fixtures/match.json').readAsStringSync()) as Map<String, dynamic>;
    final m = MatchView.fromJson(raw);
    expect(m.teams['home']!.players, hasLength((((raw['teams'] as Map)['home'] as Map)['players'] as List).length));
    expect(m.home.name, isNotEmpty);
    expect(modelErrors.where((e) => e.contains('LeagueMatch') || e.contains('MatchView')), isEmpty);
  });

  test('a trainee: his rating is the server overall (the training already in it)', () {
    final t = TrainingView.fromJson(jsonDecode(File('test/fixtures/training.json').readAsStringSync()));
    expect(t.players, isNotEmpty);
    final raw =
        Map<String, dynamic>.from(
            ((jsonDecode(File('test/fixtures/training.json').readAsStringSync()) as Map<String, dynamic>)['players'] as List<dynamic>).first
                as Map<dynamic, dynamic>,
          )
          ..['overall'] = 80
          ..['training_bonus'] = 3;
    expect(Trainee.of(TrainingPlayer.fromJson(raw)).rating, 80);
  });
}
