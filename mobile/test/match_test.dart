import 'package:dio/dio.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_error.dart';
import 'package:glm/core/live/live_channels.dart';
import 'package:glm/core/settings.dart';
import 'package:glm/features/match/frames.dart';
import 'package:glm/features/match/live_controller.dart';
import 'package:glm/features/match/live_screen.dart';
import 'package:glm/features/match/match_data.dart';
import 'package:glm/features/match/report_screen.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/live_feed.dart';

Map<String, dynamic> json(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Answers as the API would (the fixtures are the engine's own sample match), and records the orders.
class FakeMatchRepository implements MatchRepository {
  FakeMatchRepository({this.finished = false});

  final bool finished;
  final List<Map<String, Object>> orders = [];
  int readies = 0;

  @override
  Future<MatchView> show(int id) async => MatchView.fromJson({...json('match'), 'finished': finished});
  int polls = 0;

  /// The sample is in a coach's window; false answers with play going on.
  bool paused = true;

  /// [Sprint 66 T8] The network gone: every poll fails as the client says it (offline).
  bool offline = false;
  @override
  Future<LiveSync> live(int id, int since) async {
    polls++;
    if (offline) {
      throw ApiError.from(
        DioException(
          requestOptions: RequestOptions(path: '/live'),
          type: DioExceptionType.connectionError,
        ),
      );
    }
    return LiveSync.fromJson({
      ...json('live'),
      'finished': finished,
      'server_now': DateTime.now().millisecondsSinceEpoch,
      if (!paused) 'pause': null,
    });
  }

  final List<String> keys = [];
  @override
  Future<void> order(int id, Map<String, Object> order, {required String key}) async {
    keys.add(key);
    orders.add(order);
  }

  @override
  Future<void> ready(int id) async => readies++;
  @override
  Future<void> react(int id, String key, {String? target}) async => orders.add({'react': key, 'target': ?target});
  @override
  Future<void> say(int id, String body) async => orders.add({'say': body});
  @override
  Future<MatchReport> report(int id, {required bool coach}) async => MatchReport.fromReport(json('report')).withMoments(
    // [Sprint 59 F1] The recap in the server's shape (MatchRecap, every field it always sends).
    MatchReport.fromRecap({
      'match_id': 77,
      'competition': 'league',
      'round': 5,
      'home': {'id': 1, 'name': 'Arsenal', 'code': 'ARS', 'crest_url': '/crests/1.png'},
      'away': {'id': 2, 'name': 'Chelsea', 'code': 'CHE', 'crest_url': '/crests/2.png'},
      'man_of_the_match': null,
      'shootout': null,
      'score': {'home': 1, 'away': 1},
      'result': 'draw',
      'side': 'home',
      'moments': [
        {
          'minute': 24,
          'type': 'goal',
          'team': 'away',
          'player': 'Bukayo Saka',
          'other': 'Martin Ødegaard',
          'color': null,
          'score': {'home': 0, 'away': 1},
        },
      ],
      'stats': {
        'home': {
          'possession': 52,
          'shots': 13,
          'on_target': 5,
          'big_chances': 2,
          'corners': 6,
          'fouls': 9,
          'yellow': 1,
          'red': 0,
          'saves': 3,
        },
        'away': {
          'possession': 48,
          'shots': 14,
          'on_target': 4,
          'big_chances': 1,
          'corners': 3,
          'fouls': 11,
          'yellow': 2,
          'red': 0,
          'saves': 4,
        },
      },
      'best': {'home': <dynamic>[], 'away': <dynamic>[]},
    }),
  );
  @override
  Future<List<({int id, String home, String away})>> mine() async => const [];
}

Future<void> pump(WidgetTester t, Widget screen, FakeMatchRepository repo, {FakeFeed? feed, Size size = const Size(420, 1600)}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        matchRepositoryProvider.overrideWithValue(repo),
        liveFeedProvider.overrideWithValue(feed ?? FakeFeed()),
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
  // The pitch draws every frame: pump a while instead of settling.
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Leaves the screen so its poll and its pitch stop.
Future<void> wait(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> leave(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 5));
}

void main() {
  group('frames: the golden vectors (docs/api/frame-golden.json), as the web and Unity', () {
    final golden = jsonDecode(File('../docs/api/frame-golden.json').readAsStringSync()) as Map<String, dynamic>;
    final frames = [for (final f in golden['frames'] as List<dynamic>) Keyframe.fromJson(f as Map<String, dynamic>)];

    test('segments', () {
      for (final s in (golden['segments'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        final got = segment(s['count'] as int, (s['u'] as num).toDouble());
        expect(got.i, s['i'], reason: '$s');
        expect(got.k, closeTo((s['k'] as num).toDouble(), 1e-9), reason: '$s');
      }
    });

    test('samples', () {
      for (final s in (golden['samples'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        final f = sample(frames, (s['u'] as num).toDouble())!;
        final ball = s['ball'] as List<dynamic>;
        expect(
          [f.ball.$1, f.ball.$2, f.ball.$3],
          [for (final v in ball) closeTo((v as num).toDouble(), 1e-6)],
          reason: 'ball at ${s['u']}',
        );
        final players = s['players'] as Map<dynamic, dynamic>;
        expect(f.players.keys.toSet(), players.keys.toSet(), reason: 'players at ${s['u']}');
        for (final e in players.entries) {
          final want = e.value as List<dynamic>;
          expect(
            [f.players[e.key]!.$1, f.players[e.key]!.$2],
            [closeTo((want[0] as num).toDouble(), 1e-6), closeTo((want[1] as num).toDouble(), 1e-6)],
            reason: '${e.key} at ${s['u']}',
          );
        }
      }
    });
  });

  test('a live sync from the engine: the minutes, their events with the server\'s sentences, the break', () {
    final s = LiveSync.fromJson(json('live'));
    expect(s.ticks, hasLength(6));
    expect(s.ticks.last.score, (1, 1));
    expect(s.ticks.first.frames, isNotEmpty);
    expect(s.ticks.expand((t) => t.events).where((e) => e.type == 'goal'), hasLength(2));
    expect(s.pause!.window, isTrue);
    expect(s.readings, hasLength(1));
  });

  testWidgets('the live match: the score, the commentary, the break and the coach\'s orders', (t) async {
    final repo = FakeMatchRepository();
    await pump(t, const LiveMatchScreen(matchId: 77), repo);
    expect(find.text('1 - 1'), findsOneWidget);
    expect(find.textContaining('Bukayo Saka يفتتح'), findsOneWidget);
    expect(find.textContaining('لاعبك في الوسط تعب'), findsOneWidget);
    expect(find.text('النافذة مفتوحة: أوامرك الآن'), findsOneWidget);

    await t.tap(find.text('أنا مستعد'));
    await t.pump(const Duration(milliseconds: 300));
    expect(repo.readies, 1);

    // A substitution: Salah off, Szoboszlai on.
    await t.tap(find.textContaining('تبديل 3'));
    await wait(t);
    expect(find.text('يخرج'), findsOneWidget);
    await t.tap(find.text('Mohamed Salah'));
    await t.pump();
    await t.tap(find.text('Dominik Szoboszlai'));
    await t.pump();
    await t.tap(find.text('أرسل'));
    await wait(t);
    expect(repo.orders.single, {'type': 'sub', 'out': 1, 'in': 9});

    // A reaction for every viewer's screen.
    await t.tap(find.text('🔥'));
    await wait(t);
    expect(repo.orders.last, {'react': 'fire'});
    await leave(t);
  });

  testWidgets('[Sprint 60 F6] landscape: the picture alone, the score once, the orders and the chat in edge drawers', (t) async {
    final repo = FakeMatchRepository();
    await pump(t, const LiveMatchScreen(matchId: 77), repo, size: const Size(844, 390));
    expect(find.text('1 - 1'), findsOneWidget);
    // No frame: the score's bar is the only one, and the last event a line at the foot.
    expect(find.text('مباشر'), findsNothing);
    expect(find.textContaining('Alexander Isak'), findsNothing, reason: 'the break bar takes the foot in a break');
    expect(find.text('أنا مستعد'), findsOneWidget);
    // [Sprint 64 F7] The coach's window opened the orders' drawer by itself: the substitution with what is left, and
    // the assistant's notes.
    await wait(t);
    expect(find.text('0 من 3 تبديلات'), findsOneWidget);
    expect(find.textContaining('لاعبك في الوسط تعب'), findsOneWidget);
    await t.tap(find.text('تبديل'));
    await wait(t);
    expect(find.text('يخرج'), findsOneWidget);
    await t.tapAt(const Offset(5, 5));
    await wait(t);
    // The chat's drawer: the reactions and the commentary.
    await t.tap(find.text('الدردشة').first);
    await wait(t);
    expect(find.textContaining('Alexander Isak'), findsOneWidget);
    await t.tap(find.text('🔥'));
    await wait(t);
    expect(repo.orders.last, {'react': 'fire'});
    await leave(t);
  });

  testWidgets('[Sprint 53] on the channel a minute and a chat line arrive pushed, and the poll slows', (t) async {
    final repo = FakeMatchRepository();
    final feed = FakeFeed();
    await pump(t, const LiveMatchScreen(matchId: 77), repo, feed: feed);
    expect(feed.channels, ['match.77']);
    expect(find.text('1 - 1'), findsOneWidget);
    // Play goes on (no break), and the channel is up: the screen asks once for what it may have missed.
    repo.paused = false;
    feed.sub.on = true;
    await t.pump(const Duration(milliseconds: 300));
    final next = Map<String, dynamic>.from((json('live')['ticks'] as List<dynamic>).last as Map<dynamic, dynamic>)
      ..['tick'] = 27
      ..['minute'] = [27, 0]
      ..['score'] = {'home': 2, 'away': 1}
      ..['events'] = <dynamic>[]
      ..['window'] = false;
    final polls = repo.polls;
    feed.push('minute', {'match_id': 77, 'live': next, 'next_at': DateTime.now().millisecondsSinceEpoch + 3000});
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('2 - 1'), findsOneWidget);
    final chats = (json('live')['chat'] as List<dynamic>).length;
    expect(find.textContaining('الدردشة $chats'), findsOneWidget);
    feed.push('chat', {
      'match_id': 77,
      'item': {'id': 99, 'who': 'حمزة', 'body': 'هدف!', 'side': 'away', 'user_id': 3, 'at': 0},
    });
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('الدردشة ${chats + 1}'), findsOneWidget);
    // On the channel the poll waits about 12 s: none in the next 5 (it was about every 1.5 s).
    await t.pump(const Duration(seconds: 5));
    expect(repo.polls, polls);
    // The channel lost: the poll at once, then at its own pace.
    feed.sub.on = false;
    await t.pump(const Duration(milliseconds: 300));
    expect(repo.polls, polls + 1);
    await leave(t);
    expect(feed.sub.left, isTrue);
  });

  testWidgets('[Sprint 66 T8] with the network gone the poll keeps trying, and the match goes on when it is back', (t) async {
    final repo = FakeMatchRepository();
    await pump(t, const LiveMatchScreen(matchId: 77), repo);
    expect(find.text('1 - 1'), findsOneWidget);
    repo.offline = true;
    await t.pump(const Duration(seconds: 2));
    final failing = repo.polls;
    // About every 4 s while it fails: never stopped, never in a hurry.
    await t.pump(const Duration(seconds: 9));
    expect(repo.polls - failing, inInclusiveRange(2, 3));
    expect(find.text('1 - 1'), findsOneWidget, reason: 'the last known minute stays on the screen');
    repo.offline = false;
    await t.pump(const Duration(seconds: 5));
    expect(repo.polls, greaterThan(failing + 2));
    expect(find.text('1 - 1'), findsOneWidget);
    await leave(t);
  });

  testWidgets('a played match: full time and its report', (t) async {
    await pump(t, const LiveMatchScreen(matchId: 77), FakeMatchRepository(finished: true));
    expect(find.text('نهاية المباراة'), findsWidgets);
    expect(find.text('تقرير المباراة'), findsOneWidget);
    await leave(t);

    await pump(t, const MatchReportScreen(matchId: 77, coach: true), FakeMatchRepository(finished: true));
    expect(find.text('تعادل'), findsOneWidget);
    expect(find.text('لماذا هذه النتيجة'), findsOneWidget);
    // [Sprint 64 F9] The suggestion's button, to the lineup of the match's league.
    expect(find.text('إلى التشكيلة'), findsOneWidget);
    expect(find.textContaining('Bukayo Saka (Martin Ødegaard)'), findsOneWidget);
    expect(find.textContaining('Mohamed Salah'), findsWidgets);
  });

  test('[Sprint 61 F4] the live match as one value: its minutes told, its parts read apart, the channel left with it', () async {
    final repo = FakeMatchRepository();
    final feed = FakeFeed();
    final c = ProviderContainer(overrides: [matchRepositoryProvider.overrideWithValue(repo), liveFeedProvider.overrideWithValue(feed)]);
    addTearDown(c.dispose);
    final view = await c.read(matchProvider(77).future);
    final sub = c.listen(liveMatchProvider(77), (_, _) {});
    final scores = <(int, int)>[];
    c.listen(liveMatchProvider(77).select((s) => s.score), (_, s) => scores.add(s));
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final s = sub.read();
    expect(s.started, isTrue);
    expect(s.tick, greaterThan(0));
    expect(s.score, (1, 1), reason: 'the minutes already played when the screen opened are told at once');
    expect(s.feed, isNotEmpty);
    expect(s.pause, isNotNull);
    expect(s.clock, isNotNull);
    expect(scores, [(1, 1)], reason: 'the score\'s watchers hear of it once');
    expect(view.id, 77);
    expect(feed.channels, ['match.77']);
    sub.close();
    c.dispose();
    expect(feed.sub.left, isTrue);
  });
}
