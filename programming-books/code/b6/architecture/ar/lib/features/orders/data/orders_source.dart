abstract interface class OrdersSource {
  Future<Map<String, dynamic>> post(Map<String, int> items);
  Future<List<Map<String, dynamic>>> list();
}

// ينوب عن الخادم: يجيب بعد 400 جزء من الثانية، كما تفعل الشبكة.
class FakeOrdersSource implements OrdersSource {
  FakeOrdersSource({this.fails = false});

  final bool fails;
  final _orders = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> post(Map<String, int> items) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (fails) {
      throw Exception('connection refused');
    }
    final order = {
      'id': _orders.length + 1,
      'items': items,
      'status': 'pending',
      'placed_at': '2026-11-22T10:00:00',
    };
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<List<Map<String, dynamic>>> list() async => [..._orders];
}
