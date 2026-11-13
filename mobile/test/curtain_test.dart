import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/ui/widgets/motion.dart';

void main() {
  testWidgets('[Sprint 63 G2] the curtain in both shirts parts in 420ms, and shuts again before leaving', (t) async {
    Ambient.on = true;
    addTearDown(() => Ambient.on = false);
    final key = GlobalKey<MatchCurtainState>();
    await t.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            const Text('match'),
            MatchCurtain(key: key, home: Colors.red, away: Colors.blue),
          ],
        ),
      ),
    );
    final halves = find.byType(DecoratedBox);
    expect(halves, findsNWidgets(2), reason: 'shut as the match opens');
    await t.pump(const Duration(milliseconds: 200));
    expect(halves, findsNWidgets(2), reason: 'still parting');
    await t.pump(const Duration(milliseconds: 260));
    expect(halves, findsNothing, reason: 'open after 420ms');

    var shut = false;
    unawaited(key.currentState!.close().then((_) => shut = true));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(halves, findsNWidgets(2));
    await t.pumpAndSettle();
    expect(shut, isTrue);
  });
}
