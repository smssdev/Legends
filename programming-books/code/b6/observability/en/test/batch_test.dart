import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/analytics.dart';

class Sent implements EventTransport {
  final batches = <int>[];

  @override
  Future<void> send(List<Map<String, Object?>> batch) async =>
      batches.add(batch.length);
}

void main() {
  test('ten events, or thirty seconds, whichever comes first', () {
    fakeAsync((time) {
      final sent = Sent();
      final analytics = Analytics(sent)..setConsent(true);
      for (var i = 0; i < 23; i++) {
        analytics.log('scroll_menu');
      }
      time.flushMicrotasks();
      debugPrint('after 23 events:    batches of ${sent.batches}');
      time.elapse(const Duration(seconds: 29));
      debugPrint('after 29 seconds:   batches of ${sent.batches}');
      time.elapse(const Duration(seconds: 1));
      debugPrint('after 30 seconds:   batches of ${sent.batches}');
      expect(sent.batches, [10, 10, 3]);
    });
  });
}
