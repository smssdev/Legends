import 'dart:async';

import 'order.dart';

// مصدر الحقيقة لكل شاشة. الشاشات تشاهده؛ ولا تنتظر الشبكة أبداً.
abstract interface class LocalStore {
  Stream<List<Order>> watch();
  Future<List<Order>> all();
  Future<Order?> get(String id);
  Future<void> put(Order order);
  // صندوق الصادر: كل طلب فيه تغييرات لم يؤكدها الخادم بعد، الأقدم أولاً.
  Future<List<Order>> outbox();
  Future<int> cursor();
  Future<void> setCursor(int version);
}

class MemoryLocalStore implements LocalStore {
  final _orders = <String, Order>{};
  var _cursor = 0;
  final _changes = StreamController<List<Order>>.broadcast();

  // Stream.multi: القائمة الأولى والاشتراك في التغييرات يحدثان معاً، فلا يسقط تغيير بينهما.
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
    // كل تغيير يُعلن، فتتحدث كل شاشة تشاهد فوراً.
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
