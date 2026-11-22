import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/rates.dart';

void main() {
  test('الجلسات بلا انهيار لكل إصدار', () {
    final sessions = [
      for (var i = 0; i < 1000; i++) Session('1.3.0', crashed: i % 125 == 0),
      for (var i = 0; i < 400; i++) Session('1.4.0', crashed: i % 20 == 0),
    ];
    crashFreeRate(sessions).forEach(
      (version, rate) => debugPrint(
        '$version  ${rate.toStringAsFixed(1)}% of sessions without a crash',
      ),
    );
  });
}
