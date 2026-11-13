import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/api/gen/models.g.dart' as api;
import 'package:glm/core/api/api_error.dart';
import 'package:glm/core/api/intents.dart';
import 'package:glm/features/club/lineup_controller.dart';
import 'package:glm/features/club/tactics_controller.dart';
import 'package:glm/features/club/team_data.dart';
import 'package:glm/features/market/buy_controller.dart';
import 'package:glm/features/market/market_data.dart';
import 'package:glm/features/match/match_data.dart';
import 'package:glm/features/match/orders_controller.dart';
import 'package:glm/features/groups/chat_controller.dart';
import 'package:glm/features/social/social_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [Sprint 59 F5] The five editing screens' Notifiers, each with a fake repository: what is saved, what a refusal does,
// and a retry (with the same key where the action has one).

const refused = ApiError('مرفوض', status: 422);

final sample = TeamData.fromJson(jsonDecode(File('test/fixtures/team.json').readAsStringSync()) as Map<String, dynamic>);

class FakeTeam extends Fake implements TeamRepository {
  final saved = <Map<String, Object>>[];
  List<int>? starters;
  int failures = 0;

  @override
  Future<Tactics> saveTactics(int league, Map<String, Object> changes) async {
    if (failures > 0) {
      failures--;
      throw refused;
    }
    saved.add(changes);
    return Tactics({'plan': 'passing', ...changes});
  }

  @override
  Future<TeamData> saveLineup(int league, String formation, List<int> starters, List<int> bench, {List<List<int>>? positions}) async {
    if (failures > 0) {
      failures--;
      throw refused;
    }
    this.starters = starters;
    return sample;
  }
}

class FakeMarket extends Fake implements MarketRepository {
  final keys = <String>[];
  int failures = 0;

  @override
  Future<void> buy(int league, int player, {bool compensate = false, required String key}) async {
    keys.add(key);
    if (failures > 0) {
      failures--;
      throw refused;
    }
  }
}

class FakeMatch extends Fake implements MatchRepository {
  final keys = <String>[];
  final orders = <Map<String, Object>>[];
  int failures = 0;

  @override
  Future<void> order(int id, Map<String, Object> order, {required String key}) async {
    keys.add(key);
    if (failures > 0) {
      failures--;
      throw refused;
    }
    orders.add(order);
  }
}

class FakeChat extends Fake implements SocialRepository {
  final said = <String>[];
  int failures = 0;

  @override
  Future<List<api.ChatMessage>> messages(int group) async => [
    for (final (i, b) in said.indexed) api.ChatMessage(id: i + 1, body: b, kind: 'text', deleted: false, createdAt: '2026-11-06T08:00:00Z'),
  ];

  @override
  Future<void> read(int group) async {}

  @override
  Future<void> say(int group, String body, {int? replyTo}) async {
    if (failures > 0) {
      failures--;
      throw refused;
    }
    said.add(body);
  }
}

Future<ProviderContainer> container(List<Override> overrides) async {
  SharedPreferences.setMockInitialValues({});
  Intents.load(await SharedPreferences.getInstance());
  final c = ProviderContainer(overrides: overrides);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('TacticsEditor', () {
    test('changes show at once and go together after the pause', () async {
      final repo = FakeTeam();
      final c = await container([teamRepositoryProvider.overrideWithValue(repo)]);
      final sub = c.listen(tacticsEditorProvider(1), (_, _) {});
      final editor = c.read(tacticsEditorProvider(1).notifier);
      editor.set('pressing', 70, const Tactics({'pressing': 50}));
      editor.set('tempo', 30, const Tactics({'pressing': 50}));
      expect(sub.read()!.values, {'pressing': 70, 'tempo': 30});
      expect(await editor.flush(), isNull);
      expect(repo.saved, [
        {'pressing': 70, 'tempo': 30},
      ]);
    });

    test('a refused save drops the edit, and the next change saves again', () async {
      final repo = FakeTeam()..failures = 1;
      final c = await container([teamRepositoryProvider.overrideWithValue(repo)]);
      final sub = c.listen(tacticsEditorProvider(1), (_, _) {});
      final editor = c.read(tacticsEditorProvider(1).notifier);
      editor.set('pressing', 70, const Tactics({'pressing': 50}));
      expect((await editor.flush())?.message, 'مرفوض');
      expect(sub.read(), isNull);
      editor.set('pressing', 60, const Tactics({'pressing': 50}));
      expect(await editor.flush(), isNull);
      expect(repo.saved.single, {'pressing': 60});
    });
  });

  group('LineupEditor', () {
    test('a swap and its save; a refused save keeps the draft for a retry', () async {
      final repo = FakeTeam()..failures = 1;
      final c = await container([teamRepositoryProvider.overrideWithValue(repo)]);
      final sub = c.listen(lineupEditorProvider(1), (_, _) {});
      final editor = c.read(lineupEditorProvider(1).notifier);
      final l = sample.lineup;
      final a = l.starters[5], b = l.bench.firstWhere((id) => sample.byId(id)?.line != 'gk');
      final lines = {for (final p in sample.players) p.id: p.line};
      expect(editor.swap(a, b, l, l.slots, (id) => lines[id]), isTrue);
      expect(sub.read()!.starters[5], b);
      expect((await editor.save(l))?.message, 'مرفوض');
      expect(sub.read()!.starters[5], b, reason: 'the draft stays');
      expect(sub.read()!.busy, isFalse);
      expect(await editor.save(l), isNull);
      expect(repo.starters![5], b);
    });

    test('the slot rule from the server refuses a keeper in the outfield', () async {
      final c = await container([teamRepositoryProvider.overrideWithValue(FakeTeam())]);
      final editor = c.read(lineupEditorProvider(1).notifier);
      final l = sample.lineup;
      final slots = [
        for (final (i, s) in l.slots.indexed)
          Slot(role: s.role, line: s.line, x: s.x, y: s.y, allowed: i == 0 ? ['gk'] : ['def', 'mid', 'att']),
      ];
      final lines = {for (final p in sample.players) p.id: p.line};
      expect(editor.swap(l.starters[0], l.starters[3], l, slots, (id) => lines[id]), isFalse);
    });
  });

  group('BuyController', () {
    test('a refused purchase keeps its words, and the retry sends the same key', () async {
      final repo = FakeMarket()..failures = 1;
      final c = await container([marketRepositoryProvider.overrideWithValue(repo)]);
      final sub = c.listen(buyControllerProvider(1), (_, _) {});
      final buy = c.read(buyControllerProvider(1).notifier);
      expect(await buy.buy(9), isFalse);
      expect(sub.read().error, 'مرفوض');
      expect(await buy.buy(9), isTrue);
      expect(sub.read(), (busy: false, error: null));
      expect(repo.keys, hasLength(2));
      expect(repo.keys[1], repo.keys[0]);
      // The next purchase is a new one.
      await buy.buy(9);
      expect(repo.keys[2], isNot(repo.keys[0]));
    });
  });

  group('LiveOrders', () {
    test('an order, a refusal kept for the screen, and the retry with the same key', () async {
      final repo = FakeMatch()..failures = 1;
      final c = await container([matchRepositoryProvider.overrideWithValue(repo)]);
      final sub = c.listen(liveOrdersProvider(5), (_, _) {});
      final orders = c.read(liveOrdersProvider(5).notifier);
      expect(await orders.sub(1, 9), isFalse);
      expect(sub.read().error, 'مرفوض');
      expect(await orders.sub(1, 9), isTrue);
      expect(repo.orders.single, {'type': 'sub', 'out': 1, 'in': 9});
      expect(repo.keys[1], repo.keys[0]);
      expect(await orders.formation('4-4-2'), isTrue);
      expect(repo.keys[2], isNot(repo.keys[0]));
    });
  });

  group('ChatController', () {
    test('a message is sent once and listed; a refused one leaves the error and can be sent again', () async {
      final repo = FakeChat()..failures = 1;
      final c = await container([socialRepositoryProvider.overrideWithValue(repo)]);
      final sub = c.listen(chatControllerProvider(3), (_, _) {});
      final chat = c.read(chatControllerProvider(3).notifier);
      expect(await chat.send('  '), isFalse, reason: 'nothing to send');
      expect(await chat.send('مرحبا'), isFalse);
      expect(sub.read().error, 'مرفوض');
      expect(await chat.send('مرحبا'), isTrue);
      expect(sub.read().messages.single.body, 'مرحبا');
      expect(sub.read().sending, isFalse);
      expect(sub.read().error, isNull);
    });
  });
}
