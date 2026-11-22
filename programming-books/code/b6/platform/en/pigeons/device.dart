import 'package:pigeon/pigeon.dart';

// One definition; Pigeon writes the Dart, Kotlin, Swift and GObject code from it.
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/device/device_api.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/com/example/bit_app/DeviceApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.bit_app'),
    swiftOut: 'ios/Runner/DeviceApi.g.swift',
    gobjectHeaderOut: 'linux/runner/device_api.g.h',
    gobjectSourceOut: 'linux/runner/device_api.g.cc',
    gobjectOptions: GObjectOptions(module: 'Cafe'),
  ),
)
class DeviceInfo {
  DeviceInfo({
    required this.system,
    required this.version,
    required this.memoryMb,
  });

  String system;
  String version;
  int memoryMb;
}

@HostApi()
abstract class DeviceApi {
  DeviceInfo info();
  int batteryLevel();
}
