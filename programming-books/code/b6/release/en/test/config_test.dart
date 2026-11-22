import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/config.dart';

void main() {
  test('the configuration this build was given', () {
    debugPrint(
      'flavor ${AppConfig.flavor}, server ${AppConfig.apiUrl}, debug tools ${AppConfig.showDebug}',
    );
  });
}
