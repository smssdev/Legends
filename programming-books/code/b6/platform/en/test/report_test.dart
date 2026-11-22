import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/device/device_api.g.dart';
import 'package:bit_app/device/device_source.dart';
import 'package:bit_app/device_app.dart';

class Desktop implements DeviceSource {
  @override
  Future<DeviceInfo> info() async =>
      DeviceInfo(system: 'Linux', version: '6.1', memoryMb: 8000);

  @override
  Future<int> batteryLevel() => throw PlatformException(
    code: 'UNAVAILABLE',
    message: 'This device has no battery.',
  );
}

class Nowhere implements DeviceSource {
  @override
  Future<DeviceInfo> info() => throw PlatformException(code: 'channel-error');

  @override
  Future<int> batteryLevel() => throw PlatformException(code: 'channel-error');
}

void main() {
  testWidgets('a missing battery becomes a sentence', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DevicePage(source: Desktop())));
    await tester.pump();
    expect(find.text('No battery'), findsOneWidget);
    expect(find.text('8000 MB'), findsOneWidget);
  });

  testWidgets('no native side becomes a sentence', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DevicePage(source: Nowhere())));
    await tester.pump();
    expect(find.text('No native side here (channel-error)'), findsOneWidget);
  });
}
