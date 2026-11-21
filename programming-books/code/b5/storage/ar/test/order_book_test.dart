import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/order_book.dart';

void main() {
  test('السجل يُكتب في ملف ويُقرأ من جديد', () async {
    // A real folder on the disk, made for this test and removed after it.
    final dir = await Directory.systemTemp.createTemp('orders');
    addTearDown(() => dir.delete(recursive: true));

    final book = OrderBook(folder: () async => dir);
    expect(await book.load(), isEmpty);
    await book.add(const Order('سارة', 105));
    await book.add(const Order('عمر', 40));

    final again = OrderBook(folder: () async => dir);
    expect([for (final o in await again.load()) o.name], ['سارة', 'عمر']);
    expect(
      File('${dir.path}/orders.json').readAsStringSync(),
      '[{"name":"سارة","total":105},{"name":"عمر","total":40}]',
    );
  });
}
