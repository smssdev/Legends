import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/analytics.dart';

class Sent implements EventTransport {
  final batches = <List<Map<String, Object?>>>[];

  @override
  Future<void> send(List<Map<String, Object?>> batch) async =>
      batches.add(batch);
}

void main() {
  test('بلا موافقة، لا أحداث', () async {
    final sent = Sent();
    final analytics = Analytics(sent, batchSize: 2)..log('open_menu');
    analytics
      ..setConsent(true)
      ..log('open_menu')
      ..log('add_to_order', {'drink': 'latte'});
    analytics
      ..log('open_specials')
      ..setConsent(false)
      ..log('checkout');
    await analytics.flush();
    debugPrint('batches sent: ${sent.batches}');
    expect(sent.batches, hasLength(1));
  });
}
