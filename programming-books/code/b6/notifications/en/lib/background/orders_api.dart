class Order {
  const Order(this.id, this.ready);

  final String id;
  final bool ready;
}

abstract interface class OrdersApi {
  Future<List<Order>> mine();
}

abstract interface class Seen {
  Future<bool> contains(String id);
  Future<void> add(String id);
}

abstract interface class Notify {
  Future<void> orderReady(String id);
}
