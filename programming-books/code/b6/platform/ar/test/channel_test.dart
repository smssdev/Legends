import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/device/device_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('القناة باليد، مع بديل', () async {
    const channel = MethodChannel('bitcafe/device');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];

    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return {'system': 'Linux', 'version': '6.1.0', 'memoryMb': 15872};
    });
    final info = (await DeviceChannel().info())!;
    debugPrint(
      'answered: ${info.system} ${info.version}, ${info.memoryMb} MB, after calls $calls',
    );

    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'BUSY'),
    );
    await expectLater(
      DeviceChannel().info(),
      throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'BUSY')),
    );
    debugPrint(
      'an error from the platform reaches Dart as PlatformException(BUSY)',
    );

    messenger.setMockMethodCallHandler(channel, null);
    debugPrint('no handler at all: ${await DeviceChannel().info()}');
  });
}
