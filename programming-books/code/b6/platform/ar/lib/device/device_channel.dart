import 'package:flutter/services.dart';

class HostInfo {
  const HostInfo(this.system, this.version, this.memoryMb);

  final String system;
  final String version;
  final int memoryMb;
}

// القناة باليد: اسم، ودالة، وما يرسله الطرف الآخر.
class DeviceChannel {
  static const _channel = MethodChannel('bitcafe/device');

  Future<HostInfo?> info() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>('info');
      return HostInfo(
        map!['system'] as String,
        map['version'] as String,
        map['memoryMb'] as int,
      );
    } on MissingPluginException {
      // لا معالج على هذه المنصة (الويب مثلاً): ليس خطأً في التطبيق.
      return null;
    }
  }
}

const _memory = EventChannel('bitcafe/memory');

Stream<int> freeMemoryMb() => _memory.receiveBroadcastStream().cast<int>();
