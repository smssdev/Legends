import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/startup.dart';

Future<int> timed(Future<void> Function() start) async {
  final watch = Stopwatch()..start();
  await start();
  return watch.elapsedMilliseconds;
}

void main() {
  test('ثلاث خطوات، واحدة بعد الأخرى أو معاً', () async {
    debugPrint('one by one: ${await timed(startOneByOne)} ms');
    debugPrint('together:   ${await timed(startTogether)} ms');
  });
}
