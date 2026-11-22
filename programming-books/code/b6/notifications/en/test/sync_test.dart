import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/background/orders_api.dart';
import 'package:bit_app/background/sync.dart';

class FakeApi implements OrdersApi {
  @override
  Future<List<Order>> mine() async => const [
    Order('41', true),
    Order('42', true),
    Order('43', false),
  ];
}

class MemorySeen implements Seen {
  final ids = <String>{};

  @override
  Future<bool> contains(String id) async => ids.contains(id);

  @override
  Future<void> add(String id) async => ids.add(id);
}

class Recorded implements Notify {
  final sent = <String>[];

  @override
  Future<void> orderReady(String id) async => sent.add(id);
}

void main() {
  test('the background job notifies once, even when run twice', () async {
    final seen = MemorySeen();
    final notify = Recorded();
    final first = await syncOrders(FakeApi(), seen, notify);
    final second = await syncOrders(FakeApi(), seen, notify);
    expect(notify.sent, ['41', '42']);
    expect((first, second), (2, 0));
  });
}
