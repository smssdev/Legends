import 'package:flutter/services.dart';

import 'device_api.g.dart';

// التطبيق يعتمد على هذه؛ والصنف المولَّد فيه هاتان الدالتان أصلاً.
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

// كل خطأ من المنصة يصير شيئاً تستطيع الشاشة قوله.
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
