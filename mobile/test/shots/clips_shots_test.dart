@Tags(["shots"])
library;

// The cartoon clips at their key moments, for design review: flutter test test/shots/clips_shots_test.dart --tags shots --run-skipped --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/features/match/feed/art.dart';
import 'package:glm/features/match/feed/clips.dart';

Future<void> _fonts() async {
  for (final (family, files) in [('Tajawal', ['Tajawal-700', 'Tajawal-800']), ('BarlowCondensed', ['BarlowCondensed-700', 'BarlowCondensed-800'])]) {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f.ttf').readAsBytesSync())));
    }
    await l.load();
  }
}

const look = ClipLook(
  kits: {'home': (Color(0xFFC8102E), Colors.white), 'away': (Color(0xFFF3F0E6), Color(0xFF1C2333))},
  keeper: Color(0xFF7CB342), referee: Color(0xFF111111), grass: Color(0xFF1E9E4A), grassDark: Color(0xFF167A39), gold: Color(0xFFF5B82E), night: Color(0xFF0B1A2C),
);

void main() {
  final cases = <(String, String, Map<String, Object?>, double)>[
    ('goal-shot', 'goal', {'no': '11', 'passNo': '8', 'defNo': '4', 'lane': 'left', 'v': 3}, 2.8),
    ('goal-net', 'goal', {'no': '11', 'passNo': '8', 'defNo': '4', 'lane': 'left', 'v': 3}, 3.1),
    ('goal-joy', 'goal', {'no': '11', 'passNo': '8', 'defNo': '4', 'lane': 'left', 'v': 3}, 5.2),
    ('save', 'save', {'no': '9', 'defNo': '5', 'lane': 'right', 'v': 2}, 2.95),
    ('miss-post', 'miss', {'no': '9', 'how': 'post', 'lane': 'right', 'v': 2}, 3.1),
    ('penalty-wait', 'penalty', {'no': '11', 'scored': true, 'v': 4}, 3.2),
    ('freekick', 'freekick', {'no': '10', 'scored': true, 'v': 5}, 2.4),
    ('card-red', 'card', {'no': '4', 'victimNo': '11', 'type': 'red', 'drama': 'crowd', 'v': 1}, 3.8),
    ('foul-dive', 'foul', {'no': '4', 'victimNo': '11', 'drama': 'dive'}, 2.6),
    ('offside', 'offside', {'no': '9'}, 1.9),
    ('corner', 'corner', {'no': '4', 'claim': false}, 1.7),
    ('sub', 'sub', {'inNo': '20', 'outNo': '9'}, 2.5),
    ('injury', 'injury', {'no': '7'}, 3.0),
    ('rant', 'rant', {}, 1.2),
    ('whistle', 'whistle', {'name': 'halftime', 'big': 'Half time', 'home': 1, 'away': 0, 'stats': [('Shots', 7, 3), ('On target', 3, 1)]}, 2.2),
    ('var', 'var', {'no': '9', 'reason': 'offside', 'v': 3}, 7.0),
    ('slip', 'slip', {'no': '9', 'defNo': '5'}, 1.6),
    ('crowd', 'crowd', {'flares': true, 'v': 3}, 1.0),
    ('coach-joy', 'coachReact', {'side': 'home', 'look': 'C1', 'mood': 'joy'}, 1.0),
    ('studio', 'studio', {'score': '1 - 0', 'clock': "34'"}, 1.0),
  ];
  for (final (name, scene, data, u) in cases) {
    testWidgets(name, (t) async {
      t.view.physicalSize = const Size(1000, 562);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.runAsync(_fonts);
      final rain = name == 'slip';
      await t.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(child: CustomPaint(size: const Size(1000, 562), painter: ClipPainter(scene: scene, data: data, side: 'home', u: u, look: rain ? ClipLook(kits: look.kits, keeper: look.keeper, referee: look.referee, grass: look.grass, grassDark: look.grassDark, gold: look.gold, night: look.night, rain: true) : look))),
      ));
      await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('out/clip-$name.png'));
    });
  }
}
