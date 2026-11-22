import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/device/device_channel.dart';
import 'package:bit_app/device/device_source.dart';
import 'package:bit_app/device_app.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native side answers, on Linux', (tester) async {
    final byHand = (await DeviceChannel().info())!;
    debugPrint(
      'by hand: ${byHand.system} ${byHand.version}, ${byHand.memoryMb} MB',
    );
    final report = await readDevice(PigeonDevice());
    final info = report.info!;
    debugPrint(
      'pigeon:  ${info.system} ${info.version}, ${info.memoryMb} MB, battery: ${report.battery ?? report.problem}',
    );

    app.main();
    await tester.pumpAndSettle();
    expect(find.text(info.system), findsOneWidget);
    expect(find.text('No battery'), findsOneWidget);
  });
}
