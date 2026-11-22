import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/push/message.dart';
import 'package:bit_app/quiet.dart';

void main() {
  group('quiet hours', () {
    const promo = PushMessage(PushKind.promo);
    const ready = PushMessage(PushKind.orderReady, orderId: '42');
    final cases = [
      (promo, 7, 59, false),
      (promo, 8, 0, true),
      (promo, 21, 59, true),
      (promo, 22, 0, false),
      (ready, 23, 30, true),
    ];
    for (final (message, hour, minute, expected) in cases) {
      final at = DateTime(2026, 11, 23, hour, minute);
      final name =
          '${message.kind.name} at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      test(
        '$name: ${expected ? 'show' : 'wait'}',
        () => expect(showNow(message, at), expected),
      );
    }
  });
}
