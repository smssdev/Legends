import 'package:flutter/services.dart';

import 'device_api.g.dart';

// The app depends on this; the generated class already has these methods.
abstract interface class DeviceSource {
  Future<DeviceInfo> info();
  Future<int> batteryLevel();
}

class PigeonDevice extends DeviceApi implements DeviceSource {}

class DeviceReport {
  const DeviceReport({this.info, this.battery, this.problem});

  final DeviceInfo? info;
  final int? battery;
  final String? problem;
}

// Every platform error becomes something the screen can say.
Future<DeviceReport> readDevice(DeviceSource source) async {
  final DeviceInfo info;
  try {
    info = await source.info();
  } on PlatformException catch (error) {
    return DeviceReport(problem: error.code);
  }
  try {
    return DeviceReport(info: info, battery: await source.batteryLevel());
  } on PlatformException catch (error) {
    return DeviceReport(info: info, problem: error.code);
  }
}
