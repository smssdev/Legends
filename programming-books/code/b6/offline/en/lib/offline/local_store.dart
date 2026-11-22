import 'dart:async';

import 'order.dart';

// The source of truth for every screen. Screens watch it; they never wait for the network.
abstract interface class LocalStore {
  Stream<List<Order>> watch();
  Future<List<Order>> all();
  Future<Order?> get(String id);
  Future<void> put(Order order);
  // The outbox: every order with changes the server has not confirmed yet, oldest first.
  Future<List<Order>> outbox();
  Future<int> cursor();
  Future<void> setCursor(int version);
}

class MemoryLocalStore implements LocalStore {
  final _orders = <String, Order>{};
  var _cursor = 0;
  final _changes = StreamController<List<Order>>.broadcast();

  // Stream.multi: the first list and the subscription to changes happen at once, so no change can fall between them.
  @override
  Stream<List<Order>> watch() => Stream.multi((listener) {
    listener.add([..._orders.values]);
    final changes = _changes.stream.listen(listener.add);
    listener.onCancel = changes.cancel;
  });

  @override
  Future<List<Order>> all() async => [..._orders.values];

  @override
  Future<Order?> get(String id) async => _orders[id];

  @override
  Future<void> put(Order order) async {
    _orders[order.id] = order;
    // Every change is announced, so every screen that watches is updated at once.
    _changes.add(await all());
  }

  @override
  Future<List<Order>> outbox() async => [
    for (final o in _orders.values)
      if (o.sync == SyncState.queued) o,
  ];

  @override
  Future<int> cursor() async => _cursor;

  @override
  Future<void> setCursor(int version) async => _cursor = version;
}
