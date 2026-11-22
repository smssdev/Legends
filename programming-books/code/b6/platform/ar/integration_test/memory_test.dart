import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/device/device_channel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('الذاكرة الحرة، تتدفق من C++', (tester) async {
    final watch = Stopwatch()..start();
    final readings = await freeMemoryMb().take(4).toList();
    debugPrint(
      'free memory: ${readings.map((mb) => '$mb MB').join(', ')} in ${watch.elapsedMilliseconds} ms',
    );
    expect(readings, hasLength(4));
  });
}
