import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/domain/pricing.dart';

void main() {
  group('ساعة السعادة عند حدودها', () {
    final cases = {
      DateTime(2026, 11, 23, 14, 59): false,
      DateTime(2026, 11, 23, 15): true,
      DateTime(2026, 11, 23, 16, 59, 59): true,
      DateTime(2026, 11, 23, 17): false,
      DateTime(2026, 11, 23, 3, 30): false,
    };
    cases.forEach((time, expected) {
      final hhmm =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      test(
        '$hhmm is ${expected ? '' : 'not '}happy hour',
        () => expect(isHappyHour(time), expected),
      );
    });
  });
}
