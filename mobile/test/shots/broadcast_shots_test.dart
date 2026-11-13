@Tags(["shots"])
library;

// The broadcast player over the pitch at two moments of a goal: flutter test test/shots/broadcast_shots_test.dart --tags shots --run-skipped --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> _fonts() async {
  for (final (family, files) in [
    ('Tajawal', ['Tajawal-500', 'Tajawal-700', 'Tajawal-800']),
    ('BarlowCondensed', ['BarlowCondensed-700', 'BarlowCondensed-800']),
  ]) {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f.ttf').readAsBytesSync())));
    }
    await l.load();
  }
}

const look = ClipLook(
  kits: {'home': (Color(0xFFC8102E), Colors.white), 'away': (Color(0xFFF3F0E6), Color(0xFF1C2333))},
  keeper: Color(0xFF7CB342),
  referee: Color(0xFF111111),
  grass: Color(0xFF1E9E4A),
  grassDark: Color(0xFF167A39),
  gold: Color(0xFFF5B82E),
  night: Color(0xFF0B1A2C),
);

void main() {
  for (final (name, ms) in [('broadcast-pre', 1800), ('broadcast-goal', 3400)]) {
    testWidgets(name, (t) async {
      Ambient.on = true;
      GameSounds.enabled = false;
      addTearDown(() => Ambient.on = false);
      t.view.physicalSize = const Size(1000, 646);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.runAsync(_fonts);
      final play = BroadcastPlay.of(
        30,
        FeedStory(
          scene: 'goal',
          goal: true,
          side: 'home',
          head: 'هدف!',
          who: 'Mohamed Salah',
          sub: 'صناعة Szoboszlai',
          data: const {'no': '11', 'passNo': '8', 'defNo': '4', 'lane': 'left', 'v': 3, 'side': 'home'},
          pre: (head: 'هجمة خطيرة', who: 'Mohamed Salah', sub: 'Liverpool'),
        ),
        total: 14,
        moods: const {},
        tier: Tier.high,
      );
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
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
            body: BroadcastStage(look: look, queue: [play], onKey: (_) {}, child: const SizedBox()),
          ),
        ),
      );
      for (var i = 0; i < ms; i += 50) {
        await t.pump(const Duration(milliseconds: 50));
      }
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
      await t.pumpWidget(const SizedBox());
    });
  }
}
