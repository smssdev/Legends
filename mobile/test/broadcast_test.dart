import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/sounds.dart';
import 'package:glm/features/match/feed/art.dart';
import 'package:glm/features/match/feed/broadcast.dart';
import 'package:glm/features/match/feed/director.dart';
import 'package:glm/features/match/feed/story.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';
import 'package:glm/ui/widgets/motion.dart';

/// [Sprint 44 C1] The broadcast holds a minute's result until its scene reaches the key moment (the ball in the net),
/// then tells it, with the goal's banner; a tap skips the scene and tells it at once.
void main() {
  const look = ClipLook(
    kits: {'home': (Colors.red, Colors.white), 'away': (Colors.white, Colors.black)},
    keeper: Colors.green,
    referee: Colors.black,
    grass: Colors.green,
    grassDark: Colors.green,
    gold: Colors.amber,
    night: Colors.black,
  );

  Future<List<int>> stage(WidgetTester t, List<BroadcastPlay> queue) async {
    final told = <int>[];
    await t.pumpWidget(
      MaterialApp(
        theme: glmTheme(day: false),
        locale: const Locale('ar'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 360,
            child: BroadcastStage(look: look, queue: queue, onKey: told.add, child: const Text('pitch')),
          ),
        ),
      ),
    );
    return told;
  }

  setUp(() {
    Ambient.on = true;
    GameSounds.enabled = false;
  });
  tearDown(() => Ambient.on = false);

  BroadcastPlay goal() => BroadcastPlay.of(
    30,
    FeedStory(
      scene: 'goal',
      goal: true,
      side: 'home',
      head: 'هدف!',
      who: 'Salah',
      data: const {'no': '11', 'side': 'home'},
      pre: (head: 'هجمة خطيرة', who: 'Salah', sub: 'Liverpool'),
    ),
    total: 12,
    moods: const {},
    tier: Tier.high,
  );

  testWidgets('a goal: held until the ball is in, then told with its banner, then the pitch again', (t) async {
    final play = goal();
    final told = await stage(t, [play]);
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(Duration(milliseconds: (play.keyAt * 1000).round() - 300));
    expect(told, isEmpty, reason: 'not before the key moment');
    expect(find.text('هجمة خطيرة'), findsOneWidget, reason: 'the lower third hides the result');
    await t.pump(const Duration(milliseconds: 400));
    expect(told, [30]);
    expect(find.text('هدف!'), findsWidgets, reason: 'the banner and the lower third');
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('pitch'), findsOneWidget, reason: 'after the scene and its cutaways, the pitch');
  });

  testWidgets('a tap skips the scene and tells the minute at once', (t) async {
    final told = await stage(t, [goal()]);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byType(BroadcastStage));
    await t.pump();
    expect(told, [30]);
    expect(find.text('pitch'), findsOneWidget);
  });

  testWidgets('with the motion off the minute is told at once', (t) async {
    Ambient.on = false;
    final told = await stage(t, [goal()]);
    await t.pump();
    expect(told, [30]);
  });
}
