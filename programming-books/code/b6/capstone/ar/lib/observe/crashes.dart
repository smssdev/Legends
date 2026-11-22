import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class Crashes {
  Crashes(this.send);

  final void Function(Map<String, Object?> report) send;

  void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      send({'type': details.exception.runtimeType.toString(), 'fatal': false});
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      send({'type': error.runtimeType.toString(), 'fatal': true});
      return true;
    };
  }
}
