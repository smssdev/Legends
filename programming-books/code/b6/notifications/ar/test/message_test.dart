import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/push/message.dart';

void main() {
  test('رسائل الدفع تصير مسارات، أو لا شيء', () {
    final cases = <Map<String, Object?>>[
      {'type': 'order_ready', 'order_id': '42'},
      {'type': 'order_update', 'order_id': '7'},
      {'type': 'promo'},
      {'type': 'order_ready'},
      {'type': 'order_ready', 'order_id': '../admin'},
      {'type': 'unknown', 'order_id': '42'},
    ];
    for (final data in cases) {
      debugPrint(
        '${data.toString().padRight(44)} -> ${PushMessage.fromData(data)?.route ?? 'ignored'}',
      );
    }
  });
}
