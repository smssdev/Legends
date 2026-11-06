@Tags(["shots"])
library;

// The game's icon set on the arena blue: flutter test test/shots/icons_shots_test.dart --tags shots --run-skipped --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/ui/tokens.g.dart';
import 'package:glm/ui/widgets/game_icons.dart';

void main() {
  testWidgets('icons', (t) async {
    t.view.physicalSize = const Size(1000, 420);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      final l = FontLoader('BarlowCondensed')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/BarlowCondensed-800.ttf').readAsBytesSync())));
      await l.load();
    });
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        child: Container(
          color: GlmArena.blue,
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 14, runSpacing: 14, children: [for (final g in GameGlyph.values) GameIcon(g, size: 72)]),
        ),
      ),
    ));
    await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('out/icons.png'));
  });
}
