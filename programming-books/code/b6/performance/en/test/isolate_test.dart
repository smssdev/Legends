import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

String bigJson() => jsonEncode([
  for (var i = 0; i < 200000; i++)
    {
      'id': i,
      'drink': 'Latte $i',
      'price': 45,
      'extras': ['oat milk', 'vanilla'],
    },
]);

int total(String json) => (jsonDecode(json) as List).fold(
  0,
  (sum, order) => sum + (order as Map)['price'] as int,
);

// A frame is due every 16 ms: count how many times the main isolate was free to draw one.
Future<(int, int, int)> whileWorking(FutureOr<int> Function() work) async {
  var frames = 0;
  final ticker = Timer.periodic(
    const Duration(milliseconds: 16),
    (_) => frames++,
  );
  final watch = Stopwatch()..start();
  final result = await work();
  final ms = watch.elapsedMilliseconds;
  ticker.cancel();
  return (result, ms, frames);
}

void main() {
  test('frames lost while parsing a big JSON', () async {
    final json = bigJson();
    debugPrint(
      'JSON: ${(json.length / 1024 / 1024).toStringAsFixed(1)} MB, 200000 orders',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final (a, msA, framesA) = await whileWorking(() => total(json));
    debugPrint(
      'on the main isolate: $msA ms, ${msA ~/ 16} frames due, $framesA drawn',
    );
    final (b, msB, framesB) = await whileWorking(
      () => Isolate.run(() => total(json)),
    );
    debugPrint(
      'with Isolate.run:    $msB ms, ${msB ~/ 16} frames due, $framesB drawn',
    );
    expect(a, b);
  });
}
